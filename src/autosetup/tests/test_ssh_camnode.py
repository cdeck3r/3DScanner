#
# Testinfra testcases for basic ssh connects
#
# Author: cdeck3r
#

import pytest
import subprocess


@pytest.mark.usefixtures("camnode_ssh_config")
class TestSSHCamnode:
    def test_ssh_into_camnode_using_keys(self, host):
        assert host.run("hostname").succeeded

    # login using user/pass shall not work
    @pytest.mark.xfail
    @pytest.mark.parametrize('nodetype', ['camnode'])
    def test_ssh_into_camnode_using_userpass(self, pytestconfig, nodetype):
        TEST_DIR = pytestconfig.rootpath
        host = pytestconfig.getini(nodetype.lower())

        # src: https://janakiev.com/blog/python-shell-commands/
        process = subprocess.run(
            [str(TEST_DIR) + '/' + 'test_ssh_into_node_using_userpass.sh', host],
            stdout=subprocess.PIPE,
            universal_newlines=True,
        )
        # execute process
        process
        assert process.returncode == 0, "Should not login into camnode using user/pass"

    # sshkeys need to have specific permissions
    @pytest.mark.parametrize('userhome', ['/home/pi'])
    def test_sshkeys(self, host, userhome):
        # camnode's public key
        assert host.file(userhome + '/.ssh/authorized_keys').exists
        assert host.file(userhome + '/.ssh/authorized_keys').mode == 0o644
        assert host.file(userhome + '/.ssh/authorized_keys').user == 'pi'
        assert host.file(userhome + '/.ssh/authorized_keys').group == 'pi'
        assert host.file(userhome + '/.ssh').mode == 0o700
        assert host.file(userhome + '/.ssh').user == 'pi'
