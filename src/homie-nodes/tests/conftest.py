#
# Relevant pytest functions for reuse, e.g. fixtures
#
# Author: cdeck3r
#


import os
import shutil
import subprocess
import sys
from zipfile import ZipFile

import pytest
import testinfra

''' Make new ini and command line parameter visible 
'''


def pytest_addoption(parser):
    parser.addini('camnode', 'camnode hostname for testing')
    parser.addini('centralnode', 'centralnode hostname for testing')
    parser.addoption('--force', action='store_true')


''' Pings a given nodetype

The nodetype is one [ camnode | centralnode ] and used to 
find the corresponding hostname within the ini config.
'''


def can_ping(pytestconfig, nodetype):
    def ping_node(hostname, count=3):
        # src: https://janakiev.com/blog/python-shell-commands/
        process = subprocess.run(
            ['ping', '-c ' + str(count), hostname],
            stdout=subprocess.PIPE,
            universal_newlines=True,
        )
        # execute process
        process
        return process.returncode

    # parameter check
    if nodetype not in ['camnode', 'centralnode']:
        raise ValueError('nodetype not valid')

    hostname = pytestconfig.getini(nodetype)
    # discover name using a single ping; we ignore the result
    ping_node(hostname, 1)

    return ping_node(hostname) == 0


''' Configures ssh keys and parameters for a node

This function gets called by the *_ssh_config() fixtures.
It unzips the given `.zip` file into the `/tmp/autosetup`
directory for the private key. In the same directory it creates a 
ssh config and specifies the hostname in a same-named file.

'''


def node_ssh_config(request, pytestconfig, nodetype, autosetup_zip, keyfile_name):
    # variable definition (by convention)
    TEST_DIR = pytestconfig.rootpath
    AUTOSETUP_DIR = os.path.abspath('/tmp/autosetup')
    AUTOSETUP_ZIP = os.path.abspath(
        os.path.join(TEST_DIR, '..', '..', 'autosetup', autosetup_zip)
    )
    USER = 'root'
    KEYFILE = os.path.abspath(os.path.join(AUTOSETUP_DIR, keyfile_name))
    SSH_CONFIG = os.path.abspath(os.path.join(AUTOSETUP_DIR, 'ssh_config'))
    HOSTNAME = os.path.abspath(os.path.join(AUTOSETUP_DIR, 'hostname'))

    # teardown function
    def node_ssh_config_teardown():
        # teardown, cleanup
        try:
            shutil.rmtree(AUTOSETUP_DIR)
        except:
            pass

    # start of fixture
    assert os.path.exists(AUTOSETUP_ZIP), 'AUTOSETUP_ZIP does not exist'
    assert can_ping(pytestconfig, nodetype.lower())

    # prepare (pre-cleanup), unzip keyfile, set permissions
    try:
        shutil.rmtree(AUTOSETUP_DIR)
    except:
        pass
    with ZipFile(AUTOSETUP_ZIP, 'r') as zipObj:
        zipObj.extractall(AUTOSETUP_DIR)
    assert os.path.exists(KEYFILE), "KEYFILE does not exist"
    os.chmod(KEYFILE, 0o600)
    shutil.chown(KEYFILE, USER, USER)

    # create ssh config filename with correct permissions
    with open(SSH_CONFIG, "w") as f:
        f.write('Host *' + '\n')
        f.write('User pi' + '\n')
        f.write('IdentityFile ' + KEYFILE + '\n')
        f.write('UserKnownHostsFile /dev/null' + '\n')
        f.write('StrictHostKeyChecking no' + '\n')
    os.chmod(SSH_CONFIG, 0o600)  # mode = 600 in octal
    shutil.chown(SSH_CONFIG, USER, USER)  # root:root

    # store hostname for others, e.g. host fixture
    # alternative: use cache
    # src: https://docs.pytest.org/en/stable/cache.html#cache
    hostname = pytestconfig.getini(nodetype.lower())
    with open(HOSTNAME, "w") as f:
        f.write(hostname)

    # add teardown function
    request.addfinalizer(node_ssh_config_teardown)


''' Fixture to setup the ssh configuration with the camnode.

'''


@pytest.fixture(scope="class")
def camnode_ssh_config(request, pytestconfig):
    node_ssh_config(
        request, pytestconfig, 'CAMNODE', 'autosetup_centralnode.zip', 'camnode.priv'
    )
    yield


''' Fixture to setup the ssh configuration with the centralnode

'''


@pytest.fixture(scope="class")
def centralnode_ssh_config(request, pytestconfig):
    # centralnode's private key is intentionally not part of autosetup_* archives
    node_ssh_config(
        request, pytestconfig, 'CENTRALNODE', 'allkeys.zip', 'centralnode.priv'
    )
    yield


''' Host fixture for node communication via ssh

Host communication in testcases is set fixed to ssh. 
The fixture reads the hostname from the `hostname` file 
in the `/tmp/autosetup` directory. It configures the 
communication with the ssh config from the same directory.

'''


@pytest.fixture(scope="class")
def host(pytestconfig):
    # variables (by convention)
    AUTOSETUP_DIR = os.path.abspath('/tmp/autosetup')
    HOSTNAME = os.path.abspath(os.path.join(AUTOSETUP_DIR, 'hostname'))
    SSH_CONFIG = os.path.abspath(os.path.join(AUTOSETUP_DIR, 'ssh_config'))

    # files created by function camnode_ssh_config() above
    # They should exist, because of
    # "The relative order of fixtures of same scope follows the declared order
    # in the test function and honours dependencies between fixtures."
    # src: https://docs.pytest.org/en/stable/fixture.html#order-higher-scoped-fixtures-are-instantiated-first
    #
    # In the test function the host fixture is after the declaration of
    # @pytest.mark.usefixtures("camnode_ssh_config") in the class.
    #
    assert os.path.exists(HOSTNAME)
    assert os.path.exists(SSH_CONFIG)

    # read first line only to get hostname, configure host
    hostname = open(HOSTNAME, 'r').readline().rstrip().lower()
    yield testinfra.get_host("ssh://" + hostname, ssh_config=SSH_CONFIG)
