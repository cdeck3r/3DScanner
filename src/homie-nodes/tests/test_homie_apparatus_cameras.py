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
        msg = self.mqtt_sub(pytestconfig, 'scanner/apparatus/cameras/last-button-push')
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
        msg = self.mqtt_sub(pytestconfig, 'scanner/apparatus/cameras/last-button-push')
        assert datetime.fromisoformat(msg).timestamp() > last_button_push


    @pytest.mark.parametrize('waiting_time', [2])
    def test_homie_apparatus_resolution(self, pytestconfig, waiting_time):
        x_res = self.mqtt_sub(pytestconfig, 'scanner/apparatus/cameras/resolution-x')
        y_res = self.mqtt_sub(pytestconfig, 'scanner/apparatus/cameras/resolution-y')
        
        # do not allow to set neg. resolutions
        for p in [('resolution-x', x_res), ('resolution-y', y_res)]:
            self.mqtt_pub(
                pytestconfig,
                'scanner/apparatus/cameras/' + p[0] + '/set',
                str(-1),
            )
            msg = self.mqtt_sub(
                pytestconfig, 'scanner/apparatus/cameras/' + p[0],
            )
            assert msg == p[1]

        # set new valid resolution (x,y)
        x_res_new = min(int(x_res) + 100, 3280)
        y_res_new = min(int(y_res) + 100, 2464)
        
        # set new resolution (x,y)
        for p in [('resolution-x', new_x_res), ('resolution-y', new_y_res)]:
            self.mqtt_pub(
                pytestconfig,
                'scanner/apparatus/cameras/' + p[0] + '/set',
                str(p[1]),
            )        
        # add update waiting time
        time.sleep(update_waiting_time)

        # test for new resolution
        for p in [('resolution-x', new_x_res), ('resolution-y', new_y_res)]:
            msg = self.mqtt_sub(
                pytestconfig, 'scanner/apparatus/cameras/' + p[0],
            )
            assert msg == str(p[1])

        # reset to default values
        self.mqtt_pub(
            pytestconfig,
            'scanner/apparatus/cameras/default-resolution/set',
            'reset',
        )
        # add update waiting time
        time.sleep(update_waiting_time)
        
        # test for new resolution
        for p in [('resolution-x', x_res), ('resolution-y', y_res)]:
            msg = self.mqtt_sub(
                pytestconfig, 'scanner/apparatus/cameras/' + p[0],
            )
            assert msg == str(p[1])
