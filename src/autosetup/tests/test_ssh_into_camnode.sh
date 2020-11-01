#!/bin/bash

#
# SSH into camnode from 3dsdev 
# 
# Author: cdeck3r
#

# Params: none 

# this directory is the script directory
SCRIPT_DIR="$( pwd -P )"
# shellcheck disable=SC2034
SCRIPT_NAME=$0

# include config file
source ${SCRIPT_DIR}/test.cfg

# variables
AUTOSETUP_DIR=/tmp/autosetup
AUTOSETUP_ZIP="${SCRIPT_DIR}"/../autosetup_centralnode.zip
USER=root
KEYFILE=${AUTOSETUP_DIR}/camnode

#####################################################
# Fixture
#####################################################

setup_suite() {
    # check tools
    TOOLS=('ping' 'unzip' 'ssh-keyscan' 'sshpass')
    for t in "${TOOLS[@]}"
    do
        assert "which $t" "Could not find tool: $t"
    done
    
    # can ping?
    assert "ping -c 3 ${CAMNODE}" "Cannot ping camnode $CAMNODE"

    # unzip keyfile
    assert "test -f ${AUTOSETUP_ZIP}" "Could not find file: ${AUTOSETUP_ZIP}"
    assert_fail "test ${AUTOSETUP_DIR} == ${SCRIPT_DIR}" "Something is wrong. AUTOSETUP_DIR is the same as SCRIPT_DIR."
    
    rm -rf "${AUTOSETUP_DIR}"
    unzip -qq "${AUTOSETUP_ZIP}" -d "${AUTOSETUP_DIR}"
    
    assert "test -f ${KEYFILE}" "Keyfile does not exist: $KEYFILE"

    chmod 600 "${KEYFILE}"
    chown ${USER}:${USER} "${KEYFILE}"
}

teardown_suite() {
    # cleanup
    rm -rf "${AUTOSETUP_DIR}"/known_hosts
    rm -rf "${AUTOSETUP_DIR}"
} 

#####################################################
# Tests
#####################################################

test_ssh_into_camnode_using_keys() {
    SSH_CMD="ssh -i ${KEYFILE} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t pi@${CAMNODE} hostname"

    assert "${SSH_CMD}" "Could not ssh into camnode: $CAMNODE"
}

test_ssh_into_camnode_using_userpass() {
    SSH_CMD="sshpass -p raspberry ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t pi@camnode-dca632b40802 hostname"
    
    assert_fail "${SSH_CMD}" "Login with user/pass shall not work on node: $CAMNODE"
}

test_shh_into_camnode_using_keys_knownhosts() {
    # "Run ssh-keyscan to add fingerprint to known_hosts..."
    ssh-keyscan -H "${CAMNODE}" > "${AUTOSETUP_DIR}"/known_hosts 2> /dev/null
    assert "test -s ${AUTOSETUP_DIR}/known_hosts" "Problem getting fingerprint from node: ${CAMNODE}"

    SSH_CMD="ssh -i ${KEYFILE} -o UserKnownHostsFile=${AUTOSETUP_DIR}/known_hosts -t pi@${CAMNODE} hostname"
    
    assert "${SSH_CMD}" "Could not ssh into camnode: $CAMNODE"
}
