import base64
import datetime
import hashlib
import json
import logging
import os
import pathlib
import re
import shutil
import subprocess
import tempfile
import time

from homie.node.node_base import Node_Base
from homie.node.property.property_datetime import Property_DateTime
from homie.node.property.property_enum import Property_Enum
from homie.node.property.property_integer import Property_Integer

logger = logging.getLogger(__name__)


class Node_RecentImages(Node_Base):
    """The recent image taken by the camnode's camera

    scanner/apparatus/recent-images/...
    scanner/apparatus/recent-images/save-all
    scanner/apparatus/recent-images/last-saved
    scanner/apparatus/recent-images/image-count
    """
    # allowed function states
    RUN_STATES = "run,idle"

    def __init__(
        self,
        device,
        id="recent-images",
        name="All recent images",
        type_="file",
        retain=True,
        qos=1,
    ):

        super().__init__(device, id, name, type_, retain, qos)

        # important function we need
        assert self.save_all
        assert Node_RecentImages.RUN_STATES

        self.device = device

        # image storage location must exist
        self.img_dir = self.device.device_settings['img_dir']
        assert os.path.isdir(self.img_dir)

        """scanner/apparatus/recent-images/save-all"""
        # function's default state is 'idle'
        self.prop_save_all = Property_Enum(
            node=self,
            id="save-all",
            name="Save all images",
            data_format=Node_RecentImages.RUN_STATES,
            set_value=self.save_all,
            value='idle',
        )
        self.current_run_state = self.prop_save_all.value
        self.add_property(self.prop_save_all)

        """
        scanner/apparatus/recent-images/last-saved
        scanner/apparatus/recent-images/image-count
        """
        self.last_saved = Property_DateTime(
            node=self, id='last-saved', name='Most recent image date'
        )
        self.image_count = Property_Integer(
            node=self, id='image-count', name='Count of saved images', settable=False
        )

        self.add_property(self.image_count)
        self.add_property(self.last_saved)

    def __str__(self):
        return str(self.__class__.__name__)

    def save_all(self, action):
        """Collects recent images from all camera nodes and stores them"""

        def finalize(tmpdir):
            # Delete tmpdir and inform clients
            try:
                shutil.rmtree(tmpdir)
            except OSError as e:
                logger.error("Error deleting {} : {}".format(dir_path, e.strerror))
            self.current_run_state = 'idle'
            self.prop_save_all.value = self.current_run_state

        if action != 'run':
            return
        if self.current_run_state == 'run':
            return
        self.current_run_state = 'run'
        self.prop_save_all.value = self.current_run_state

        # retrieve recent-image json with b64 encoded images in tmp dir
        # decode images
        # filter out the ones which are too old (e.g. by camnode defect)
        # store them in IMAGE_DIR
        # update properties

        # Explain: decode is before filter,
        # because we need to load the complete json file anyway to filter,
        # so we can decode the b64 data

        # retrieve images
        tmpdir_root = self.device.device_settings['img_tmp_dir']
        tmpdir = tempfile.mkdtemp(dir=tmpdir_root)
        try:
            imgs = self.retrieve_images_from_camnodes(tmpdir)
        except Exception as e:
            logger.error(
                'Download of recent images failed unexpectedly: {}'.format(e.strerror)
            )
            finalize(tmpdir)
            return

        # images paths in imgs list: <tmp>/camnode-<hwaddr>_recent-image.json
        # decode
        imgs = self.decode_images(imgs)
        if len(imgs) == 0:
            logger.info('No decoded images found.')
            finalize(tmpdir)
            return
        # filter
        imgs = self.filter_images(imgs)
        # copy & store
        img_dir = ImageDir(self.img_dir)
        img_dir.copy_files_from(imgs)

        # update properties
        self.last_saved.value = img_dir.mtime
        self.image_count.value = len(img_dir.files)

        # cleanup
        finalize(tmpdir)

    def retrieve_images_from_camnodes(self, tmpdir):
        """Download all b64 encoded images and return list of file paths"""

        # download b64 data in json structure in tmp directoy
        # collect all names and return
        dest = str(tmpdir)
        broker = self.device.mqtt_settings['MQTT_BROKER']
        port = str(self.device.mqtt_settings['MQTT_PORT'])
        # remember: when the homie service starts it sets the cwd
        # to the script's directoy
        process = subprocess.run(
            [
                str(os.getcwd()) + '/' + 'node_recentimages_download.sh',
                broker,
                port,
                dest,
            ],
            capture_output=True,
            universal_newlines=True,
            check=True,
        )
        return [
            os.path.join(tmpdir, filename)
            for filename in os.listdir(tmpdir)
            if os.path.getsize(os.path.join(tmpdir, filename)) > 0
        ]

    def decode_images(self, imgs):
        """B64 decode all images found in given list"""
        decoded_imgs = []

        for img in imgs:
            try:
                with open(os.path.abspath(img), 'r') as jsonfile:
                    j = json.load(jsonfile)
            except Exception as e:
                logger.warn('Could not load file {}: {}'.format(img, e.strerror))
                continue
            try:
                filename = os.path.basename(j['file'])
                filedir = os.path.dirname(img)
                decoded_img = base64.b64decode(j['b64file'])
                decoded_img_path = os.path.join(filedir, filename)
                with open(decoded_img_path, 'wb+') as f:
                    f.write(decoded_img)
            except Exception as e:
                logger.warn('Could not b64decode {}: {}'.format(img, e.strerror))
            decoded_imgs.append(decoded_img_path)

        return decoded_imgs

    def filter_images(self, imgs, minutes_back=10):
        """Filter images which do not match the criteria and return new list"""

        # expected camnode filename format: <tmp>/yyyymmddhhmmss_<hwaddr>.png
        imgs_filename = [os.path.basename(os.path.abspath(f)) for f in imgs]
        imgs_tmpdir = os.path.dirname(os.path.abspath(imgs[-1]))

        pattern = re.compile(r'^\d\d\d\d\d\d\d\d\d\d\d\d\d\d_')
        camnode_imgs = [
            i for i in imgs_filename if re.search(pattern, i) and i.endswith('.png')
        ]

        # extract youngest one; sub couple of minutes to form a threshold
        # sort and filter all out which are below the threshold
        youngest_img = sorted(camnode_imgs, key=str.lower)[-1]
        ts_str = re.split(r'_', youngest_img)[0]
        ts = datetime.datetime.strptime(ts_str, '%Y%m%d%H%M%S')
        threshold = ts - datetime.timedelta(minutes=minutes_back)
        threshold_str = threshold.strftime('%Y%m%d%H%M%S')

        filtered_imgs = [
            os.path.join(imgs_tmpdir, f)
            for f in sorted(camnode_imgs, key=str.lower)
            if f > threshold_str
        ]
        return filtered_imgs


class ImageDir(object):
    """Represents all information to store images"""

    def __init__(self, root_img_dir):
        """Creates a new directoy within root_img_dir"""
        assert os.path.isdir(root_img_dir)

        # format is yyyymmdd-HHmmss
        now = datetime.datetime.now()
        imgdirname = now.strftime('%Y%m%d-%H%M%S')
        self.img_dir = os.path.join(root_img_dir, imgdirname)
        os.mkdir(self.img_dir)

        assert os.path.isdir(self.img_dir)

    @property
    def path(self):
        return os.path.abspath(self.img_dir)

    @property
    def mtime(self):
        modTimesinceEpoc = os.path.getmtime(self.path)
        return time.strftime('%Y-%m-%dT%H:%M:%S.000', time.localtime(modTimesinceEpoc))

    @property
    def files(self):
        """Returns a file list from directoy"""
        return os.listdir(self.path)

    def copy_to(self, dest_dir):
        """Copy the content from image dir to destination directory"""
        # TODO: not pythonic :-(
        raise NotImplementedError

    def copy_from(self, src_dir):
        """Copy all files from src_dir to image directory"""
        self.copy_files_from(os.listdir(src_dir))

    def copy_files_from(self, src_files):
        """Copy files from list to image directory"""
        for f in src_files:
            try:
                shutil.copy2(f, self.path)
            except Exception:
                logger.warn('File copy failed: {}'.format(f))
