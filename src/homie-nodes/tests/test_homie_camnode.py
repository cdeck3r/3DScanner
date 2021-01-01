#
# Testing homie description for camnode's camera
#
# Author: cdeck3r
#

import pytest

@pytest.mark.usefixtures("camnode_ssh_config")
class TestHomieCamnode:

    def test_homie_camnode(self, host):
        assert host.file('/home/pi/homie-camnode/homie_camnode.yml').exists
