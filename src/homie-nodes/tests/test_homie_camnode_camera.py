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

    def test_homie_camnode_camera_settable(self, pytestconfig):
        camnode = pytestconfig.getini('camnode_hostname')
        msg = self.mqtt_sub(pytestconfig, 'scanner/' + camnode + '/camera/shutter-button/$settable')
        assert msg == 'true'
        msg = self.mqtt_sub(pytestconfig, 'scanner/' + camnode + '/camera/shutter-timer/$settable')
        assert msg == 'true'
        msg = self.mqtt_sub(pytestconfig, 'scanner/' + camnode + '/camera/resolution-x/$settable')
        assert msg == 'true'
        msg = self.mqtt_sub(pytestconfig, 'scanner/' + camnode + '/camera/resolution-y/$settable')
        assert msg == 'true'
        msg = self.mqtt_sub(pytestconfig, 'scanner/' + camnode + '/camera/def-resolution/$settable')
        assert msg == 'true'

    @pytest.mark.parametrize('update_waiting_time', [2])
    def test_homie_camnode_camera_timer(self, pytestconfig, update_waiting_time):
        camnode = pytestconfig.getini('camnode_hostname')
        msg = self.mqtt_sub(
            pytestconfig, 'scanner/' + camnode + '/camera/shutter-timer'
        )
        assert msg == '0'
        initial_timeout = msg
        
        # do not allow to set negative values
        timeout = -1
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
        assert msg == initial_timeout
        
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

    @pytest.mark.parametrize('update_waiting_time', [2])
    def test_homie_camnode_camera_resolution(self, pytestconfig, update_waiting_time):
        camnode = pytestconfig.getini('camnode_hostname')
        x_res = self.mqtt_sub(pytestconfig, 'scanner/' + camnode + '/camera/resolution-x')
        y_res = self.mqtt_sub(pytestconfig, 'scanner/' + camnode + '/camera/resolution-y')
        
        # do not allow to set neg. resolutions
        self.mqtt_pub(
            pytestconfig,
            'scanner/' + camnode + '/camera/resolution-x/set',
            str(-1),
        )
        msg = self.mqtt_sub(
            pytestconfig, 'scanner/' + camnode + '/camera/resolution-x'
        )
        assert msg == x_res

        self.mqtt_pub(
            pytestconfig,
            'scanner/' + camnode + '/camera/resolution-y/set',
            str(-1),
        )
        msg = self.mqtt_sub(
            pytestconfig, 'scanner/' + camnode + '/camera/resolution-y'
        )
        assert msg == y_res
        
        
        # set new valid resolution (x,y)
        x_res_new = min(int(x_res) + 100, 3280)
        y_res_new = min(int(y_res) + 100, 2464)
        
        # set new resolution (x,y)
        self.mqtt_pub(
            pytestconfig,
            'scanner/' + camnode + '/camera/resolution-x/set',
            str(x_res_new),
        )        
        self.mqtt_pub(
            pytestconfig,
            'scanner/' + camnode + '/camera/resolution-y/set',
            str(y_res_new),
        )
        # add update waiting time
        time.sleep(update_waiting_time)
        
        msg = self.mqtt_sub(
            pytestconfig, 'scanner/' + camnode + '/camera/resolution-x'
        )
        assert msg == str(x_res_new)
        assert int(msg) == min(int(x_res) + 100, 3280)
        
        msg = self.mqtt_sub(
            pytestconfig, 'scanner/' + camnode + '/camera/resolution-y'
        )
        assert msg == str(y_res_new)
        assert int(msg) == min(int(y_res) + 100, 2464)
        
        # reset to default values
        self.mqtt_pub(
            pytestconfig,
            'scanner/' + camnode + '/camera/resolution-reset/set',
            'reset',
        )
        # add update waiting time
        time.sleep(update_waiting_time)
        
        msg = self.mqtt_sub(
            pytestconfig, 'scanner/' + camnode + '/camera/resolution-x'
        )
        assert msg == x_res
        msg = self.mqtt_sub(
            pytestconfig, 'scanner/' + camnode + '/camera/resolution-y'
        )
        assert msg == y_res
