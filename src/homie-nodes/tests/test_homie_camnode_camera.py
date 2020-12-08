#
# Testing homie description for camnode's camera
#
# Author: cdeck3r
#

import subprocess
import time

import pytest


class TestHomieCamnodeCamera:
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

    @pytest.mark.parametrize('update_waiting_time', [2])
    def test_homie_camnode_timer(self, pytestconfig, update_waiting_time):
        camnode = pytestconfig.getini('camnode')
        msg = self.mqtt_sub(
            pytestconfig, 'scanner/' + camnode + '/camera/shutter-timer'
        )
        assert msg == '0'
        # publish timeout value, and read-out
        timeout = 1000
        self.mqtt_pub(
            pytestconfig,
            'scanner/' + camnode + '/camera/shutter-timer/set',
            str(timeout),
        )
        # add update waiting time
        time.sleep(update_waiting_time)
        msg = self.mqtt_sub(
            pytestconfig, 'scanner/' + camnode + '/camera/shutter-timer'
        )
        assert msg == str(timeout)
        # reset to 0
        timeout = 0
        self.mqtt_pub(
            pytestconfig,
            'scanner/' + camnode + '/camera/shutter-timer/set',
            str(timeout),
        )
        # add update waiting time
        time.sleep(update_waiting_time)
        msg = self.mqtt_sub(
            pytestconfig, 'scanner/' + camnode + '/camera/shutter-timer'
        )
        assert msg == str(timeout)
