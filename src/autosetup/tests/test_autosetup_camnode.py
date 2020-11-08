#
# Test infra test
#
# Author: cdeck3r
#

import pytest


#####################################################
# Tests
#####################################################

@pytest.mark.usefixtures("camnode_ssh_config")
class TestAutosetupCamnode:

    def test_hostname(self, pytestconfig, host):
        hostname = pytestconfig.getini('camnode')
        assert host.run("hostname").stdout.rstrip() == hostname
        

    def test_booter_done(self, host):
        assert host.file('/boot/booter.done').exists


    def test_autosetup_nodetype(self, host):
        assert host.file('/boot/autosetup/NODETYPE').exists
        assert host.file('/boot/autosetup/NODETYPE').contains("CAMNODE")


    def test_autosetup_repo_exists(self, host): 
        assert host.file('/boot/autosetup/3DScanner/.git').is_directory


    def test_autosetup_git_installed(self, host):
        pkg = host.package('git')
        assert pkg.is_installed
        assert pkg.version.startswith('1:2.20')    
