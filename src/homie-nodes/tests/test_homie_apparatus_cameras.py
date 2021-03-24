#
# Testing homie description for apparatus's cameras
#
# Author: cdeck3r
#

import subprocess

import time
from datetime import datetime

import pytest


class TestHomieApparatusCameras:
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
    def test_homie_apparatus_shutter_button(self, pytestconfig, waiting_time):
        msg = self.mqtt_sub(
            pytestconfig, 'scanner/apparatus/cameras/last-button-push'
        )
        # convert msg in number
        last_button_push = datetime.fromisoformat(msg).timestamp()

        # push the shutter-button, and read-out the last-button-push
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
        assert datetime.fromisoformat(msg).timestamp() > last_button_push 

