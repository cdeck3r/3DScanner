#
# Testing homie description for scanner apparatus
#
# Author: cdeck3r
#
import subprocess

import pytest


@pytest.mark.usefixtures("centralnode_ssh_config")
class TestHomieApparatus:
    def test_homie_apparatus_config(self, host):
        assert host.file('/home/pi/homie-apparatus/homie_apparatus.yml').exists

    def test_homie_apparatus_directories(self, host):
        # see definition in homie-apparatus/homie_apparatus.yml
        assert host.file('/home/pi/www-images').is_directory
        assert host.file('/home/pi/tmp').is_directory

    def mqtt_sub(self, pytestconfig, topic, wait=2):
        broker = pytestconfig.getini('mqttbroker')
        # execute process
        process = subprocess.run(
            ['mosquitto_sub', '-h', broker, '-t', topic, '-W', str(wait)],
            stdout=subprocess.PIPE,
            universal_newlines=True,
        )
        return process.stdout.rstrip()

    # use MQTT subscribe to run the following test cases
    def test_homie_apparatus_state(self, pytestconfig):
        msg = self.mqtt_sub(pytestconfig, 'scanner/apparatus/$state')
        assert msg == 'ready'

    def test_homie_apparatus_version(self, pytestconfig):
        msg = self.mqtt_sub(pytestconfig, 'scanner/apparatus/$homie')
        assert msg == '4.0.0'

    # @pytest.mark.skip(reason='DEV: homie device runs in dev system, not on Raspi')
    def test_homie_apparatus_attributes(self, pytestconfig):
        msg = self.mqtt_sub(pytestconfig, 'scanner/apparatus/$name')
        assert msg == "apparatus"
        msg = self.mqtt_sub(pytestconfig, 'scanner/apparatus/$implementation')
        assert msg.startswith('Full body DIY Raspberry Pi based 3D scanner')
        msg = self.mqtt_sub(pytestconfig, 'scanner/apparatus/$fw/name')
        assert msg.startswith('3DScanner')
        msg = self.mqtt_sub(pytestconfig, 'scanner/apparatus/$fw/version')
        assert len(msg) > 0

    def test_homie_apparatus_nodes(self, pytestconfig):
        msg = self.mqtt_sub(pytestconfig, 'scanner/apparatus/$nodes')
        assert msg == 'cameras,recent-images'

    def test_homie_apparatus_recentimages(self, pytestconfig):
        msg = self.mqtt_sub(pytestconfig, 'scanner/apparatus/recent-images/$name')
        assert msg == 'All recent images'
        msg = self.mqtt_sub(pytestconfig, 'scanner/apparatus/recent-images/$properties')
        assert msg == 'save-all,image-count,last-saved'

    def test_homie_apparatus_cameras(self, pytestconfig):
        msg = self.mqtt_sub(pytestconfig, 'scanner/apparatus/cameras/$name')
        assert msg == 'All cameras'
        msg = self.mqtt_sub(pytestconfig, 'scanner/apparatus/cameras/$type')
        assert msg == 'camera'
        msg = self.mqtt_sub(pytestconfig, 'scanner/apparatus/cameras/$properties')

        assert all(p in msg for p in ['shutter-button', 'last-button-push', 'online', 'online-percent', 'default-resolution', 'resolution-x', 'resolution-y'])
        
        for p in ['resolution-x', 'resolution-y']:
            msg = self.mqtt_sub(
                pytestconfig, 'scanner/apparatus/cameras/' + p + '/$settable'
            )
            assert msg == 'true'
            msg = self.mqtt_sub(
                pytestconfig, 'scanner/apparatus/cameras/' + p + '/$datatype'
            )
            assert msg == 'integer'

        for p in ['online', 'online-percent']:
            msg = self.mqtt_sub(
                pytestconfig, 'scanner/apparatus/cameras/' + p + '/$settable'
            )
            assert msg == 'false'
            msg = self.mqtt_sub(
                pytestconfig, 'scanner/apparatus/cameras/' + p + '/$datatype'
            )
            assert msg == 'integer'

        msg = self.mqtt_sub(pytestconfig, 'scanner/apparatus/cameras/online')
        assert int(msg) >= 1
