#
# Testing homie description for camnode
#
# Author: cdeck3r
#

import subprocess

import pytest


class TestHomieMQTT:
    def mqtt_sub(self, pytestconfig, topic, wait=2):
        broker = pytestconfig.getini('mqttbroker')
        process = subprocess.run(
            ['mosquitto_sub', '-h', broker, '-t', topic, '-W', str(wait)],
            stdout=subprocess.PIPE,
            universal_newlines=True,
        )
        # execute process
        return process.stdout.rstrip()

    def test_homie_camnode_version(self, pytestconfig):
        camnode = pytestconfig.getini('camnode')
        msg = self.mqtt_sub(pytestconfig, 'scanner/' + camnode + '/$homie')
        assert msg == '4.0.0'

    @pytest.mark.skip(reason='DEV: homie device runs in dev system, not on Raspi')
    def test_homie_camnode_attributes(self, pytestconfig):
        camnode = pytestconfig.getini('camnode')
        msg = self.mqtt_sub(pytestconfig, 'scanner/' + camnode + '/$name')
        assert msg == camnode
        msg = self.mqtt_sub(pytestconfig, 'scanner/' + camnode + '/$implementation')
        assert msg.startswith('Raspberry Pi')
        msg = self.mqtt_sub(pytestconfig, 'scanner/' + camnode + '/$fw/name')
        assert msg.startswith('Raspbian')
        msg = self.mqtt_sub(pytestconfig, 'scanner/' + camnode + '/$fw/version')
        assert len(msg) > 0

    def test_homie_camnode_camera(self, pytestconfig):
        camnode = pytestconfig.getini('camnode')
        msg = self.mqtt_sub(pytestconfig, 'scanner/' + camnode + '/camera/$name')
        assert msg == 'Camera'
        msg = self.mqtt_sub(pytestconfig, 'scanner/' + camnode + '/camera/$properties')
        assert msg == 'shutter-button,shutter-timer'

    def test_homie_camnode_software(self, pytestconfig):
        camnode = pytestconfig.getini('camnode')
        msg = self.mqtt_sub(pytestconfig, 'scanner/' + camnode + '/software/$name')
        assert msg == 'Software'
        msg = self.mqtt_sub(
            pytestconfig, 'scanner/' + camnode + '/software/$properties'
        )
        assert msg == 'repo-revision,local-revision'
