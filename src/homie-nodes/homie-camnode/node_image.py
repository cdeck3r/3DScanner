import base64
import hashlib
import json
import os
import pathlib
import time
from datetime import datetime

from homie.node.node_base import Node_Base
from homie.node.property.property_datetime import Property_DateTime
from homie.node.property.property_string import Property_String


class Node_Image(Node_Base):
    """The recent image taken by the camnode's camera

    scanner/camnode-hwaddr/recent-image/...
    scanner/camnode-hwaddr/recent-image/filename
    scanner/camnode-hwaddr/recent-image/datetime
    scanner/camnode-hwaddr/recent-image/file
    """

    # image file storage directoy
    IMAGE_DIR = os.path.join(pathlib.Path.home(), 'images')

    def __init__(
        self,
        device,
        id="recent-image",
        name="Recent Image",
        type_="file",
        retain=True,
        qos=1,
    ):

        super().__init__(device, id, name, type_, retain, qos)

        os.makedirs(Node_Image.IMAGE_DIR, mode=0o755, exist_ok=True)
        assert os.path.exists(Node_Image.IMAGE_DIR)

        self.device_name = device.name

        self.filename = Property_String(node=self, id='filename', name='Filename')
        self.datetime = Property_DateTime(node=self, id='datetime', name='File Date')

        file_meta = {}
        file_meta['encoding'] = {}
        file_meta['encoding']['name'] = 'file encoding'
        file_meta['encoding']['value'] = 'base64'
        file_meta['hashfunc'] = {}
        file_meta['hashfunc']['name'] = 'hashlib'
        file_meta['hashfunc']['value'] = 'blake2s'
        file_meta['jsonfiledata'] = {}
        file_meta['jsonfiledata']['name'] = 'json_var'
        file_meta['jsonfiledata']['value'] = 'b64file'
        file_meta['jsonfilehash'] = {}
        file_meta['jsonfilehash']['name'] = 'json_var'
        file_meta['jsonfilehash']['value'] = 'filehash'
        self.file = Property_String(node=self, id='file', name='File', meta=file_meta)

        self.add_property(self.filename)
        self.add_property(self.datetime)
        self.add_property(self.file)

    def __str__(self):
        return str(self.__class__.__name__)

    def new_filename(self):
        """Format: date_hwaddr.png"""
        device_name = self.device_name
        now = datetime.now()  # current date and time
        dt = now.strftime('%Y%m%d%H%M%S')
        return dt + '_' + device_name + '.png'

    def new_file(self):
        return os.path.join(Node_Image.IMAGE_DIR, self.new_filename())

    def update_recent_image(self, file):
        """Refreshes the recent-image node"""
        imgfile = ImageFile(file)

        self.filename.value = imgfile.filename
        self.datetime.value = imgfile.mtime
        self.file.value = imgfile.json


class ImageFile(object):
    """Represents all information about an image file"""

    def __init__(self, file):
        assert os.path.exists(file)
        self.file = file
        self.b64file = self.b64(file)
        self.hashfunc = 'blake2s'
        self.filehash = self.blake2s(file)

    @property
    def filename(self):
        return os.path.basename(self.file)

    @property
    def mtime(self):
        #modTimesinceEpoc = os.path.getmtime(self.file)
        #return time.strftime('%Y-%m-%dT%H:%M:%S.000', time.localtime(modTimesinceEpoc))
        modTime = datetime.fromtimestamp(os.stat(self.file).st_mtime)
        return modTime.strftime('%Y-%m-%dT%H:%M:%S.%f')

    @property
    def json(self):
        return json.dumps(self.__dict__)

    def b64(self, file):
        with open(file, 'rb') as f:
            b64string = base64.b64encode(f.read()).decode('ASCII')
        return b64string

    def blake2s(self, file):
        hash_blake2s = hashlib.blake2s()
        with open(file, 'rb') as f:
            for chunk in iter(lambda: f.read(4096), b''):
                hash_blake2s.update(chunk)
        return hash_blake2s.hexdigest()
