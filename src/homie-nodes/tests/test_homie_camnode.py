#
# Testing homie description for camnode
#
# Author: cdeck3r
#
import subprocess

import pytest


@pytest.mark.usefixtures("camnode_ssh_config")
class TestHomieCamnode:
    def mqtt_sub(self, pytestconfig, topic, wait=2):
        broker = pytestconfig.getini('mqttbroker')
        process = subprocess.run(
            ['mosquitto_sub', '-h', broker, '-t', topic, '-W', str(wait)],
            stdout=subprocess.PIPE,
            universal_newlines=True,
        )
        # execute process
        return process.stdout.rstrip()

    def test_homie_camnode_configfile(self, host):
        assert host.file('/home/pi/homie-camnode/homie_camnode.yml').exists

    # use MQTT subscribe to run the following test cases
    def test_homie_camnode_state(self, pytestconfig):
        camnode = pytestconfig.getini('camnode_hostname')
        msg = self.mqtt_sub(pytestconfig, 'scanner/' + camnode + '/$state')
        assert msg == 'ready'

    def test_homie_camnode_version(self, pytestconfig):
        camnode = pytestconfig.getini('camnode_hostname')
        msg = self.mqtt_sub(pytestconfig, 'scanner/' + camnode + '/$homie')
        assert msg == '4.0.0'

    # @pytest.mark.skip(reason='DEV: homie device runs in dev system, not on Raspi')
    def test_homie_camnode_attributes(self, pytestconfig):
        camnode = pytestconfig.getini('camnode_hostname')
        msg = self.mqtt_sub(pytestconfig, 'scanner/' + camnode + '/$name')
        assert msg == camnode
        msg = self.mqtt_sub(pytestconfig, 'scanner/' + camnode + '/$implementation')
        assert msg.startswith('Raspberry Pi')
        msg = self.mqtt_sub(pytestconfig, 'scanner/' + camnode + '/$fw/name')
        assert msg.startswith('Raspbian')
        msg = self.mqtt_sub(pytestconfig, 'scanner/' + camnode + '/$fw/version')
        assert len(msg) > 0

    def test_homie_camnode_camera(self, pytestconfig):
        camnode = pytestconfig.getini('camnode_hostname')
        msg = self.mqtt_sub(pytestconfig, 'scanner/' + camnode + '/camera/$name')
        assert msg == 'Camera'
        msg = self.mqtt_sub(pytestconfig, 'scanner/' + camnode + '/camera/$properties')
        assert all(p in msg for p in ['shutter-button','shutter-timer','resolution-x','resolution-y','def-resolution','revision'] )

    def test_homie_camnode_software(self, pytestconfig):
        camnode = pytestconfig.getini('camnode_hostname')
        msg = self.mqtt_sub(pytestconfig, 'scanner/' + camnode + '/software/$name')
        assert msg == 'Software'
        msg = self.mqtt_sub(
            pytestconfig, 'scanner/' + camnode + '/software/$properties'
        )
        assert msg == 'repo-revision,local-revision'

    def test_homie_camnode_recent_image(self, pytestconfig):
        camnode = pytestconfig.getini('camnode_hostname')
        msg = self.mqtt_sub(pytestconfig, 'scanner/' + camnode + '/recent-image/$name')
        assert msg == 'Recent Image'
        msg = self.mqtt_sub(
            pytestconfig, 'scanner/' + camnode + '/recent-image/$properties'
        )
        msg = self.mqtt_sub(pytestconfig, 'scanner/' + camnode + '/recent-image/$type')
        assert msg == 'file'
        msg = self.mqtt_sub(
            pytestconfig, 'scanner/' + camnode + '/recent-image/$properties'
        )
        assert msg == 'filename,datetime,file'
        msg = self.mqtt_sub(
            pytestconfig, 'scanner/' + camnode + '/recent-image/file/$datatype'
        )
        assert msg == 'string'
        msg = self.mqtt_sub(
            pytestconfig, 'scanner/' + camnode + '/recent-image/file/$meta/$mainkey-ids'
        )
        assert msg == 'encoding,hashfunc,jsonfiledata,jsonfilehash'
        msg = self.mqtt_sub(
            pytestconfig,
            'scanner/' + camnode + '/recent-image/file/$meta/jsonfiledata/$key',
        )
        assert msg == 'json_var'
        msg = self.mqtt_sub(
            pytestconfig,
            'scanner/' + camnode + '/recent-image/file/$meta/jsonfiledata/$value',
        )
        assert msg == 'b64file'

