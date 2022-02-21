#
# Testing the scanner apparatus from end to end
#
# Contains:
# * trigger all cameras
# * save all images
#
# Author: cdeck3r
#

import subprocess
import time
from datetime import datetime

import pytest


# Hack from: https://github.com/pytest-dev/pytest/issues/3403#issuecomment-526554447
class ValueStorage:
    last_button_push = None
    last_saved = None
    dir_count = None


@pytest.mark.usefixtures("centralnode_ssh_config")
class TestHomieApparatusEnd2End:
    """Complex test szenario.

    We rely on pytest to run the testcases in
    the sequence of the test_* methods from this file.
    """

    def mqtt_sub(self, pytestconfig, topic, wait=2):
        broker = pytestconfig.getini('mqttbroker')
        process = subprocess.run(
            ['mosquitto_sub', '-h', broker, '-t', topic, '-W', str(wait)],
            stdout=subprocess.PIPE,
            universal_newlines=True,
            check=True,
        )
        # execute process
        return process.stdout.rstrip()

    def mqtt_pub(self, pytestconfig, topic, msg):
        broker = pytestconfig.getini('mqttbroker')
        process = subprocess.run(
            ['mosquitto_pub', '-h', broker, '-t', topic, '-m', msg],
            stdout=subprocess.PIPE,
            universal_newlines=True,
            check=True,
        )
        # execute process
        return process.stdout.rstrip()

    def test_homie_apparatus_cameras_last_button_push(self, host, pytestconfig):
        # scanner/apparatus/cameras/last-button-push
        msg = None
        msg = self.mqtt_sub(pytestconfig, 'scanner/apparatus/cameras/last-button-push')
        ValueStorage.last_button_push = datetime.fromisoformat(msg).timestamp()
        assert msg is not None

    def test_homie_apparatus_recent_images_last_saved(self, host, pytestconfig):
        msg = None
        # scanner/apparatus/recent-images/last-saved
        msg = self.mqtt_sub(pytestconfig, 'scanner/apparatus/recent-images/last-saved')
        ValueStorage.last_saved = datetime.fromisoformat(msg).timestamp()
        assert msg is not None

    @pytest.mark.parametrize('img_dir', ['/home/pi/www-images'])
    def test_homie_apparatus_storage_dir_count(self, host, pytestconfig, img_dir):
        # count dirs in storage directory BEFORE picture is taken
        ValueStorage.dir_count = int(
            host.run('ls -l ' + img_dir + ' | wc -l').stdout.rstrip()
        )
        assert (
            ValueStorage.dir_count >= 1
        )  # if there is no dir, there is a line in the ls -l output

    @pytest.mark.parametrize('waiting_time', [2])
    def test_homie_apparatus_camera_shutter_button(
        self, host, pytestconfig, waiting_time
    ):
        # TAKE picture: push the shutter-button
        time.sleep(waiting_time)
        self.mqtt_pub(
            pytestconfig,
            'scanner/apparatus/cameras/shutter-button/set',
            'push',
        )
        assert True

    @pytest.mark.parametrize('waiting_time', [2])
    def test_homie_apparatus_cameras_last_button_push_check(
        self, host, pytestconfig, waiting_time
    ):
        time.sleep(waiting_time)
        msg = self.mqtt_sub(pytestconfig, 'scanner/apparatus/cameras/last-button-push')
        # last-button-push timestamp must change
        assert datetime.fromisoformat(msg).timestamp() > ValueStorage.last_button_push

    @pytest.mark.parametrize('waiting_time', [2])
    def test_homie_apparatus_recent_images_save_all(
        self, host, pytestconfig, waiting_time
    ):
        # Sleep another waiting and save all images
        time.sleep(waiting_time)
        self.mqtt_pub(
            pytestconfig,
            'scanner/apparatus/recent-images/save-all/set',
            'run',
        )
        assert True

    @pytest.mark.parametrize('waiting_time', [20])
    def test_homie_apparatus_recent_images_last_saved_check(
        self, host, pytestconfig, waiting_time
    ):
        time.sleep(waiting_time)
        msg = self.mqtt_sub(pytestconfig, 'scanner/apparatus/recent-images/last-saved')
        # last-saved timestamp must change
        assert datetime.fromisoformat(msg).timestamp() > ValueStorage.last_saved

    def test_homie_apparatus_recent_images_image_count(self, host, pytestconfig):
        msg = self.mqtt_sub(pytestconfig, 'scanner/apparatus/recent-images/image-count')
        # image count must be at least one (it's the picture we just took)
        assert int(msg) >= 1

    @pytest.mark.parametrize('img_dir', ['/home/pi/www-images'])
    def test_homie_apparatus_storage_dir_count_check(self, host, pytestconfig, img_dir):
        # More directories in storage dir after
        assert (
            int(host.run('ls -l ' + img_dir + ' | wc -l').stdout.rstrip())
            > ValueStorage.dir_count
        )
