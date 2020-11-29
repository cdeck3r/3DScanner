#
# Testing homie description for camnode
#
# Author: cdeck3r
#

import pytest


class TestHomieMQTT:
    @pytest.mark.skip(reason='not yet implemented')
    @pytest.mark.parametrize('broker', ['centralnode'])
    def test_homie_mqtt(self, pytestconfig, broker):
        broker_name = pytestconfig.getini(broker.lower())
        # subscribe to homie topic
        # read message
        # compare to defined device spec
