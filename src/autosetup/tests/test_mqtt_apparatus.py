#
# Testinfra testcases to test mqtt topics for scanner/apparatus
#
# Author: cdeck3r
#

import pytest

#####################################################
# Tests
#####################################################


@pytest.mark.usefixtures("centralnode_ssh_config")
class TestMQTTApparatus:
    @pytest.mark.parametrize('broker', ['centralnode'])
    def test_autosetup_mqtt_apparatus_ready(self, pytestconfig, broker, host):
        # we use the installed mosquitto client
        broker_name = pytestconfig.getini(broker.lower())
        topic = r'scanner/apparatus/\$state'
        mqtt_sub = 'mosquitto_sub -h ' + broker_name + ' -t ' + topic + ' -W 2'
        assert host.run(mqtt_sub).stdout.rstrip() == 'ready'

    @pytest.mark.parametrize('broker', ['centralnode'])
    @pytest.mark.parametrize(
        'topic',
        [
            'scanner/apparatus/recent-images/last-saved',
            'scanner/apparatus/cameras/last-button-push',
            'scanner/apparatus/recent-images/last-saved',
        ],
    )
    def test_autosetup_mqtt_apparatus_last(self, pytestconfig, broker, topic, host):
        # we use the installed mosquitto client
        broker_name = pytestconfig.getini(broker.lower())
        mqtt_sub = 'mosquitto_sub -h ' + broker_name + ' -t ' + topic + ' -W 2'
        assert len(host.run(mqtt_sub).stdout.rstrip()) > 0

    @pytest.mark.parametrize('broker', ['centralnode'])
    @pytest.mark.parametrize(
        'topic',
        [
            r'scanner/apparatus/recent-images/save-all/\$settable',
            r'scanner/apparatus/cameras/shutter-button/\$settable',
        ],
    )
    def test_autosetup_mqtt_apparatus_settable(self, pytestconfig, broker, topic, host):
        # we use the installed mosquitto client
        broker_name = pytestconfig.getini(broker.lower())
        mqtt_sub = 'mosquitto_sub -h ' + broker_name + ' -t ' + topic + ' -W 2'
        assert host.run(mqtt_sub).stdout.rstrip() == 'true'
