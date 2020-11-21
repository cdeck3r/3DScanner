#
# Testinfra testcases to validate the autosetup run.
#
# Author: cdeck3r
#

import os
import subprocess

import pytest

#####################################################
# Tests
#####################################################


@pytest.mark.usefixtures("camnode_ssh_config")
class TestRerunAutosetupCamnode:
    """Rerun autosetup

    Test procedure:
    1. remove files and test that files are missing
    2. remove some selected software packages and test that software packages are removed
    3. start `rerun_autosetup.sh`
    4. run `test_autosetup_<..>.py` unit test

    """

    def rerun_autosetup(self, script_dir, hostname):
        # src: https://janakiev.com/blog/python-shell-commands/
        process = subprocess.run(
            [str(script_dir) + '/' + 'rerun_autosetup.sh', hostname],
            stdout=subprocess.PIPE,
            universal_newlines=True,
        )
        # execute process
        process
        # reboots performs a hard disconnect from client, ret code == 255
        assert process.returncode == 255, "rerun_autosetup.sh failed"

    @pytest.mark.parametrize('nodetype', ['camnode'])
    def test_rerun_autosetup(self, pytestconfig, host, nodetype):
        # skip, if --force not provided
        force = pytestconfig.getoption('--force', skip=True)
        if force is False:
            pytest.skip('Specify --force option to run this test.')

        TEST_DIR = pytestconfig.rootpath
        hostname = pytestconfig.getini(nodetype.lower())
        # prepare test conditions
        assert host.run('sudo rm -rf /boot/autosetup').succeeded
        # git is installed by autosetup.sh
        host.run('sudo apt-get remove git')
        # mosquitto-clients is installed by src/raspi-autosetup/install_<...>.sh script
        host.run('sudo apt-get remove mosquitto-clients')
        # SUT
        script_dir = os.path.abspath(os.path.join(TEST_DIR, '..'))
        self.rerun_autosetup(script_dir, hostname)
