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
def camnode_ssh_config(pytestconfig):
    # variables (by convention)
    TEST_DIR = pytestconfig.rootpath
    AUTOSETUP_DIR = os.path.abspath('/tmp/autosetup')
    AUTOSETUP_ZIP = os.path.abspath(os.path.join(TEST_DIR, '..', 'autosetup_centralnode.zip'))
    USER = 'root'
    KEYFILE = os.path.abspath(os.path.join(AUTOSETUP_DIR, 'camnode.priv'))
    SSH_CONFIG = os.path.abspath(os.path.join(AUTOSETUP_DIR, 'ssh_config'))
    HOSTNAME = os.path.abspath(os.path.join(AUTOSETUP_DIR, 'hostname'))

    assert os.path.exists(AUTOSETUP_ZIP), 'AUTOSETUP_ZIP does not exist'
    assert can_ping(pytestconfig, 'camnode')
    
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
    os.chmod(SSH_CONFIG, 0o600) # mode = 600 in octal
    shutil.chown(SSH_CONFIG, USER, USER) # root:root

    # store hostname for others, e.g. host fixture
    # alternative: use cache
    # src: https://docs.pytest.org/en/stable/cache.html#cache
    hostname = pytestconfig.getini('camnode')
    with open(HOSTNAME, "w") as f:
        f.write(hostname)

    yield 

    # teardown, cleanup
    try:
        shutil.rmtree(AUTOSETUP_DIR)
    except:
        pass

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
    yield testinfra.get_host("ssh://"+hostname, ssh_config=SSH_CONFIG)
