#
# Testinfra testcases to test mqtt topics for scanner/apparatus
#
# Author: cdeck3r
#

import pytest

#####################################################
# Tests
#####################################################

# We test MQTT using the mosquitto client on the camnode


@pytest.mark.usefixtures("camnode_ssh_config")
class TestMQTTApparatus:
    @pytest.mark.parametrize('broker', ['centralnode'])
    @pytest.mark.parametrize('camnode', ['camnode_hostname'])
    def test_autosetup_mqtt_camnode_ready(self, pytestconfig, broker, camnode, host):
        # we use the installed mosquitto client on the camnode
        broker_name = pytestconfig.getini(broker.lower())
        camnode_hostname = pytestconfig.getini(camnode.lower())
        topic = 'scanner/' + camnode_hostname + r'/\$state'
        mqtt_sub = 'mosquitto_sub -h ' + broker_name + ' -t ' + topic + ' -W 2'
        assert host.run(mqtt_sub).stdout.rstrip() == 'ready'

    @pytest.mark.parametrize('broker', ['centralnode'])
    @pytest.mark.parametrize('camnode', ['camnode_hostname'])
    @pytest.mark.parametrize('subtopic', ['/recent-image/datetime'])
    def test_autosetup_mqtt_camnode_datetime(
        self, pytestconfig, broker, camnode, subtopic, host
    ):
        # we use the installed mosquitto client on the camnode
        broker_name = pytestconfig.getini(broker.lower())
        camnode_hostname = pytestconfig.getini(camnode.lower())
        topic = r'scanner/' + camnode_hostname + subtopic
        mqtt_sub = 'mosquitto_sub -h ' + broker_name + ' -t ' + topic + ' -W 2'
        assert len(host.run(mqtt_sub).stdout.rstrip()) > 0

    @pytest.mark.parametrize('broker', ['centralnode'])
    @pytest.mark.parametrize('camnode', ['camnode_hostname'])
    @pytest.mark.parametrize('subtopic', [r'/camera/shutter-button/\$settable'])
    def test_autosetup_mqtt_camnode_settable(
        self, pytestconfig, broker, camnode, subtopic, host
    ):
        # we use the installed mosquitto client on the camnode
        broker_name = pytestconfig.getini(broker.lower())
        camnode_hostname = pytestconfig.getini(camnode.lower())
        topic = r'scanner/' + camnode_hostname + subtopic
        mqtt_sub = 'mosquitto_sub -h ' + broker_name + ' -t ' + topic + ' -W 2'
        assert host.run(mqtt_sub).stdout.rstrip() == 'true'

    @pytest.mark.parametrize('broker', ['centralnode'])
    @pytest.mark.parametrize('camnode', ['camnode_hostname'])
    def test_autosetup_mqtt_camnode_sw(self, pytestconfig, broker, camnode, host):
        # we use the installed mosquitto client on the camnode
        broker_name = pytestconfig.getini(broker.lower())
        camnode_hostname = pytestconfig.getini(camnode.lower())
        sw_rev_topics = [
            'scanner/' + camnode_hostname + '/software/repo-revision',
            'scanner/' + camnode_hostname + '/software/local-revision',
        ]

        sw_revs = []
        # retrieve software versions
        for i in range(len(sw_rev_topics)):
            mqtt_sub = (
                'mosquitto_sub -h ' + broker_name + ' -t ' + sw_rev_topics[i] + ' -W 2'
            )
            assert len(host.run(mqtt_sub).stdout.rstrip()) > 0
            sw_revs.append(host.run(mqtt_sub).stdout.rstrip())

        # compare sw revisions, thanks https://stackoverflow.com/a/3844948
        assert len(sw_revs) > 0
        assert sw_revs.count(sw_revs[0]) == len(sw_revs)
