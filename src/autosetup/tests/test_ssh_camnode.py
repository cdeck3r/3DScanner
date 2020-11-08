#
# Test infra test
#
# Author: cdeck3r
#

import pytest
import subprocess

@pytest.mark.usefixtures("camnode_ssh_config")
class TestSSHCamnode:

    def test_ssh_into_camnode_using_keys(self, host):
        assert host.run("hostname").succeeded
        
    @pytest.mark.xfail
    def test_ssh_into_camnode_using_userpass(self, pytestconfig):
        TEST_DIR = pytestconfig.rootpath
        host = pytestconfig.getini('camnode')
    
        # src: https://janakiev.com/blog/python-shell-commands/
        process = subprocess.run([str(TEST_DIR) + '/' + 'test_ssh_into_node_using_userpass.sh', host],
                                    stdout=subprocess.PIPE,
                                    universal_newlines=True)
        # execute process
        process
        assert process.returncode == 0, "Should not login into camnode using user/pass"

