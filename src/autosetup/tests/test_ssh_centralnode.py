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

    # sshkeys need to have specific permissions 
    @pytest.mark.parametrize('userhome', ['/home/pi'])
    def test_sshkeys(self, host, userhome):
        # centralnode's public key
        assert host.file(userhome+'/.ssh/authorized_keys').exists
        assert host.file(userhome+'/.ssh/authorized_keys').mode == 0o644
        assert host.file(userhome+'/.ssh/authorized_keys').user == 'pi'
        assert host.file(userhome+'/.ssh/authorized_keys').group == 'pi'
        assert host.file(userhome+'/.ssh').mode == 0o700
        assert host.file(userhome+'/.ssh').user == 'pi'

    # sshkeys need to have specific permissions 
    @pytest.mark.parametrize('userhome', ['/home/pi'])
    def test_sshkeys_for_camnode(self, host, userhome):
        # private key for camnode
        assert host.file(userhome+'/.ssh/id_rsa').exists
        assert host.file(userhome+'/.ssh/id_rsa').mode == 0o600
        assert host.file(userhome+'/.ssh/id_rsa').user == 'pi'
        assert host.file(userhome+'/.ssh/id_rsa').group == 'pi'

    # using centralnode as jump server
    # 3dsdev -ssh-> centralnode -remote_ssh_cmd-> camnode
    @pytest.mark.parametrize('nodetype', ['camnode'])
    def test_ssh_from_centralnode_into_camnode(self, pytestconfig, host, nodetype):    
        camnode = pytestconfig.getini(nodetype.lower())
        remote_ssh_cmd = 'ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t pi@' + camnode + ' hostname'
        assert host.run(remote_ssh_cmd).succeeded

