#
# Relevant pytest functions for reuse, e.g. fixtures
#
# Author: cdeck3r
# 


from zipfile import ZipFile
import os
import sys
import shutil
import subprocess
import testinfra
import pytest

def pytest_addoption(parser):
    parser.addini('camnode', 'camnode hostname for testing')
    parser.addini('centralnode', 'centralnode hostname for testing')

def can_ping(pytestconfig, nodetype):
    def ping_node(hostname, count=3):
        # src: https://janakiev.com/blog/python-shell-commands/
        process = subprocess.run(['ping', '-c ' + str(count), hostname],
                                    stdout=subprocess.PIPE,
                                    universal_newlines=True)
        # execute process
        process
        return process.returncode
    
    hostname = pytestconfig.getini(nodetype)
    # discover name using a single ping; we ignore the result
    ping_node(hostname, 1)

    return ping_node(hostname) == 0

@pytest.fixture(scope="class")
def host(pytestconfig):
    # variables
    AUTOSETUP_DIR = os.path.abspath('/tmp/autosetup')
    SSH_CONFIG = os.path.abspath(os.path.join(AUTOSETUP_DIR, 'ssh_config'))
    hostname = pytestconfig.getini('camnode')
    yield testinfra.get_host("ssh://"+hostname, ssh_config=SSH_CONFIG)

@pytest.fixture(scope="class")
def camnode_ssh_config(pytestconfig):
    # variables
    TEST_DIR = pytestconfig.rootpath
    AUTOSETUP_DIR = os.path.abspath('/tmp/autosetup')
    AUTOSETUP_ZIP = os.path.abspath(os.path.join(TEST_DIR, '..', 'autosetup_centralnode.zip'))
    USER = 'root'
    KEYFILE = os.path.abspath(os.path.join(AUTOSETUP_DIR, 'camnode.priv'))
    SSH_CONFIG = os.path.abspath(os.path.join(AUTOSETUP_DIR, 'ssh_config'))

    assert os.path.exists(AUTOSETUP_ZIP), 'AUTOSETUP_ZIP does not exist'
    assert can_ping(pytestconfig, 'camnode')
    try:
        shutil.rmtree(AUTOSETUP_DIR)
    except:
        pass
    with ZipFile(AUTOSETUP_ZIP, 'r') as zipObj:
        zipObj.extractall(AUTOSETUP_DIR)
    assert os.path.exists(KEYFILE), "KEYFILE does not exist"

    os.chmod(KEYFILE, 0o600) 
    shutil.chown(KEYFILE, USER, USER) 
        
    # create ssh config filename
    with open(SSH_CONFIG, "w") as f:   
        f.write('Host *' + '\n')
        f.write('User pi' + '\n')       
        f.write('IdentityFile ' + KEYFILE + '\n')
        f.write('UserKnownHostsFile /dev/null' + '\n')
        f.write('StrictHostKeyChecking no' + '\n')
    os.chmod(SSH_CONFIG, 0o600) # mode = 600 in octal
    shutil.chown(SSH_CONFIG, USER, USER) # root:root
        
    #hostname = pytestconfig.getini('camnode')
    #host = testinfra.get_host("ssh://"+hostname, ssh_config=SSH_CONFIG)
    yield 
    # teardown, cleanup
    try:
        shutil.rmtree(AUTOSETUP_DIR)
    except:
        pass
    