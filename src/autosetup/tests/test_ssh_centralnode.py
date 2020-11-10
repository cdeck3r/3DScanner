#
# Testinfra testcases for basic ssh connects
#
# Author: cdeck3r
#

import pytest
import subprocess

@pytest.mark.usefixtures("centralnode_ssh_config")
class TestSSHCentralnode:

    def test_ssh_into_centralnode_using_keys(self, host):
        assert host.run("hostname").succeeded
    
    # login using user/pass shall not work
    @pytest.mark.xfail
    @pytest.mark.parametrize('nodetype', ['centralnode'])
    def test_ssh_into_centralnode_using_userpass(self, pytestconfig, nodetype):
        TEST_DIR = pytestconfig.rootpath
        host = pytestconfig.getini(nodetype.lower())
    
        # src: https://janakiev.com/blog/python-shell-commands/
        process = subprocess.run([str(TEST_DIR) + '/' + 'test_ssh_into_node_using_userpass.sh', host],
                                    stdout=subprocess.PIPE,
                                    universal_newlines=True)
        # execute process
        process
        assert process.returncode == 0, "Should not login into centralnode using user/pass"

