#
# Testinfra testcases to test mqtt
#
# Author: cdeck3r
#

import random

import pytest

#####################################################
# Tests
#####################################################


@pytest.mark.usefixtures("camnode_ssh_config")
class TestMQTTCamnode:
    @pytest.mark.parametrize('broker', ['centralnode'])
    def test_autosetup_mqtt_publish(self, pytestconfig, broker, host):
        # we use the installed mosquitto client
        broker_name = pytestconfig.getini(broker.lower())
        msg = '"Test message from ' + __file__ + '"'
        mqtt_pub = 'mosquitto_pub -h ' + broker_name + ' -t camnode/test -m ' + msg
        assert host.run(mqtt_pub).succeeded

    @pytest.mark.parametrize('broker', ['centralnode'])
    def test_autosetup_mqtt_subscribe(self, pytestconfig, broker, host):
        # 1. publish retained msg with random number
        # 2. subscribe to received msg with random number
        #
        # we use the installed mosquitto client

        broker_name = pytestconfig.getini(broker.lower())
        rnum = random.randint(0, 1000)
        msg = 'Test message from ' + __file__ + ' with random number ' + str(rnum)

        mqtt_pub = (
            'mosquitto_pub -h '
            + broker_name
            + ' -t camnode/test --retain -m '
            + '"'
            + msg
            + '"'
        )
        assert host.run(mqtt_pub).succeeded
        mqtt_sub = 'mosquitto_sub -h ' + broker_name + ' -t camnode/test -W 2'
        assert host.run(mqtt_sub).stdout.rstrip() == msg

    @pytest.mark.parametrize('broker', ['centralnode'])
    def test_autosetup_mqtt_clear_retained_msg(self, pytestconfig, broker, host):
        # 1. publish retained msg with random number
        # 2. subscribe to received msg with random number
        # 3. publish an empty retained msg
        #
        # we use the installed mosquitto client

        broker_name = pytestconfig.getini(broker.lower())
        rnum = random.randint(0, 1000)
        msg = 'Test message from ' + __file__ + ' with random number ' + str(rnum)

        mqtt_pub = (
            'mosquitto_pub -h '
            + broker_name
            + ' -t camnode/test --retain -m '
            + '"'
            + msg
            + '"'
        )
        assert host.run(mqtt_pub).succeeded
        mqtt_sub = 'mosquitto_sub -h ' + broker_name + ' -t camnode/test -W 2'
        assert host.run(mqtt_sub).stdout.rstrip() == msg

        msg = ''
        mqtt_pub = (
            'mosquitto_pub -h '
            + broker_name
            + ' -t camnode/test --retain -m '
            + '"'
            + msg
            + '"'
        )
        assert host.run(mqtt_pub).succeeded
        mqtt_sub = 'mosquitto_sub -h ' + broker_name + ' -t camnode/test -W 2'
        assert host.run(mqtt_sub).stdout.rstrip() == ''
