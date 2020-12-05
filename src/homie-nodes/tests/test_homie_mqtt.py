#
# Testing homie description for camnode
#
# Author: cdeck3r
#

import pytest
import subprocess


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

        
    #@pytest.mark.skip(reason='not yet implemented')
    def test_homie_camnode_version(self, pytestconfig):
        camnode = pytestconfig.getini('camnode')
        msg = self.mqtt_sub(pytestconfig, 'scanner/'+camnode+'/$homie')
        assert msg == '4.0.0'
        
    def test_homie_camnode_name(self, pytestconfig):
        camnode = pytestconfig.getini('camnode')
        msg = self.mqtt_sub(pytestconfig, 'scanner/'+camnode+'/$name')
        assert msg == camnode
    
    def test_homie_camnode_camera(self, pytestconfig):
        camnode = pytestconfig.getini('camnode')
        msg = self.mqtt_sub(pytestconfig, 'scanner/'+camnode+'/camera/$name')
        assert msg == 'Camera'
        msg = self.mqtt_sub(pytestconfig, 'scanner/'+camnode+'/camera/$properties')
        assert msg == 'shutter-button'
    
    def test_homie_camnode_software(self, pytestconfig):
        camnode = pytestconfig.getini('camnode')
        msg = self.mqtt_sub(pytestconfig, 'scanner/'+camnode+'/software/$name')
        assert msg == 'Software'
        msg = self.mqtt_sub(pytestconfig, 'scanner/'+camnode+'/software/$properties')
        assert msg == 'repo-revision,local-revision'



