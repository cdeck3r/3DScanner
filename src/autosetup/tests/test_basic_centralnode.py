#
# Testinfra testcases for proper centralnode networking
#
# As a result of the booter service, the centralnode shall be reachable
# in the network using the hostname `centralnode-<hwaddr>`.
#
# Author: cdeck3r
#

import subprocess

import pytest


class TestBasicCentralnode:
    def ping_node(self, host):
        # src: https://janakiev.com/blog/python-shell-commands/
        process = subprocess.run(
            ['ping', '-c 3', host], stdout=subprocess.PIPE, universal_newlines=True
        )
        # execute process
        process
        return process.returncode

    @pytest.mark.parametrize('nodetype', ['centralnode'])
    def test_ping_centralnode(self, pytestconfig, nodetype):
        host = pytestconfig.getini(nodetype.lower())
        assert self.ping_node(host) == 0

    @pytest.mark.xfail
    @pytest.mark.parametrize('nodetype', ['centralnode'])
    def test_ping_node(self, pytestconfig, nodetype):
        host = pytestconfig.getini(nodetype.lower())
        addr_start_idx = len(nodetype + '-')
        addr_end_idx = addr_start_idx + 12
        addr = host[addr_start_idx:addr_end_idx]
        assert self.ping_node('node-' + addr + '.local') == 0, "Setup to centralnode not completed"

    @pytest.mark.xfail
    def test_ping_node0(self):
        host = 'node-000000000000' + '.local'
        assert self.ping_node(host) == 0, "Setup not completed"

    @pytest.mark.xfail
    @pytest.mark.parametrize('nodetype', ['centralnode'])
    def test_ping_centralnode0(self, nodetype):
        host = nodetype.lower() + '-000000000000' + '.local'
        assert (
            self.ping_node(host) == 0
        ), "Strange: centralnode has no eth0 hardware address."
