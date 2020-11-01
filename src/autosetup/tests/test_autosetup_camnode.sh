#!/bin/bash

#
# Test camnode autosetup from 3dsdev 
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
    TOOLS=('ping' 'unzip' 'tr')
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

test_hostname() {
    SSH_CMD="ssh -i ${KEYFILE} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t pi@${CAMNODE} hostname"
    SSH_RETVAL=$(${SSH_CMD} 2>/dev/null)
    SSH_RETVAL=$(echo ${SSH_RETVAL} | tr -d '\r\f\n')

    assert "test ${SSH_RETVAL} == ${CAMNODE}" "Hostname is not camnode: $CAMNODE"
}

test_booter_done () {
    SSH_CMD="ssh -i ${KEYFILE} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t pi@${CAMNODE} ls /boot/booter.done"
    SSH_RETVAL=$(${SSH_CMD} 2>/dev/null)
    SSH_RETVAL=$(echo ${SSH_RETVAL} | tr -d '\r\f\n')

    assert "test ${SSH_RETVAL} == '/boot/booter.done'" "Booter has not successfully completed on camnode: $CAMNODE"
}

test_autosetup_nodetype () {
    SSH_CMD="ssh -i ${KEYFILE} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t pi@${CAMNODE} head -1 /boot/autosetup/NODETYPE"
    SSH_RETVAL=$(${SSH_CMD} 2>/dev/null)
    SSH_RETVAL=$(echo ${SSH_RETVAL} | tr -d '\r\f\n')

    assert "test ${SSH_RETVAL} == 'CAMNODE'" "Node is not configured as CAMNODE: $CAMNODE"
}

test_autosetup_repo_exists () {
    SSH_CMD="ssh -i ${KEYFILE} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t pi@${CAMNODE} ls -d /boot/autosetup/3DScanner/.git"
    SSH_RETVAL=$(${SSH_CMD} 2>/dev/null)
    SSH_RETVAL=$(echo ${SSH_RETVAL} | tr -d '\r\f\n')

    assert "test ${SSH_RETVAL} == '/boot/autosetup/3DScanner/.git'" "Autosetup has not cloned 3DScanner repo on node: $CAMNODE"
}

# source: https://stackoverflow.com/a/20460402
stringContain() { [ -z "$1" ] || { [ -z "${2##*$1*}" ] && [ -n "$2" ];};}

test_autosetup_git_installed () {
    SSH_CMD="ssh -i ${KEYFILE} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t pi@${CAMNODE} git --version"
    SSH_RETVAL=$(${SSH_CMD} 2>/dev/null)
    SSH_RETVAL=$(echo ${SSH_RETVAL} | tr -d '\r\f\n')

    RES=$(if stringContain 'git version' "${SSH_RETVAL}"; then echo 0; else echo 1; fi)

    assert "test $RES -eq 0" "git not installed on node: $CAMNODE"
}
