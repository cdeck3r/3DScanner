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


@pytest.mark.usefixtures("centralnode_ssh_config")
class TestHomieApparatusEnd2End:
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

    @pytest.mark.parametrize('waiting_time', [2])
    @pytest.mark.parametrize('img_dir', ['/home/pi/www-images'])
    def test_homie_apparatus_end2end(self, host, pytestconfig, waiting_time, img_dir):
        # scanner/apparatus/cameras/last-button-push
        msg = self.mqtt_sub(
            pytestconfig, 'scanner/apparatus/cameras/last-button-push'
        )
        last_button_push = datetime.fromisoformat(msg).timestamp()

        # scanner/apparatus/recent-images/last-saved
        msg = self.mqtt_sub(
            pytestconfig, 'scanner/apparatus/recent-images/last-saved'
        )
        last_saved = datetime.fromisoformat(msg).timestamp()

        # count dirs in storage directory BEFORE picture is taken
        dir_count = int(host.run('ls -l ' + img_dir + ' | wc -l').stdout.rstrip())
        assert dir_count >= 1

        # TAKE picture: push the shutter-button
        time.sleep(waiting_time)
        self.mqtt_pub(
            pytestconfig,
            'scanner/apparatus/cameras/shutter-button/set',
            'push',
        )
        time.sleep(waiting_time)
        msg = self.mqtt_sub(
            pytestconfig, 'scanner/apparatus/cameras/last-button-push'
        )
        # last-button-push timestamp must change
        assert datetime.fromisoformat(msg).timestamp() > last_button_push 

        # Sleep another waiting and save all images
        time.sleep(waiting_time)
        self.mqtt_pub(
            pytestconfig,
            'scanner/apparatus/recent-images/save-all/set',
            'run',
        )
        time.sleep(3*waiting_time)
        msg = self.mqtt_sub(
            pytestconfig, 'scanner/apparatus/recent-images/last-saved'
        )
        # last-saved timestamp must change
        assert datetime.fromisoformat(msg).timestamp() > last_saved
        
        msg = self.mqtt_sub(
            pytestconfig, 'scanner/apparatus/recent-images/image-count'
        )
        # image count must be at least one (it's the picture we just took)
        assert int(msg) >= 1
        # More directories in storage dir after 
        assert int(host.run('ls -l ' + img_dir + ' | wc -l').stdout.rstrip()) > dir_count 
