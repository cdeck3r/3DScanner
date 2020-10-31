#!/bin/bash

#
# bash_unit test to reach camnode
# 
# Author: cdeck3r
#

# Params: none 

# Exit codes
# 1: if pre-requisites are not fulfilled
# 2: fatal error prohibiting further progress, see terminal window


# this directory is the script directory
SCRIPT_DIR="$( pwd -P )"
# shellcheck disable=SC2034
SCRIPT_NAME=$0

# variables
CAMNODE="camnode-dca632b40802"


#####################################################
# Include Helper functions
#####################################################

# ...

#####################################################
# Fixture
#####################################################

setup_suite() {
    # check tools
    TOOLS=('ping')
    for t in "${TOOLS[@]}"
    do
        assert "which $t" "Could not find tool: $t"
    done
}

#####################################################
# Tests
#####################################################

test_ping_camnode() {
    assert "ping -c 3 ${CAMNODE}" "Cannot ping camnode $CAMNODE"
}

test_ping_node() {
    NODE="node-$(echo ${CAMNODE} | cut -d'-' -f2)"
    assert_fail  "ping -c 3 ${NODE}" "Setup to camnode not completed: $NODE"
}

test_ping_node0() {
    NODE="node-000000000000"
    assert_fail  "ping -c 3 ${NODE}" "Setup not completed: $NODE"
}

test_ping_camnode0() {
    NODE="camnode-000000000000"
    assert_fail  "ping -c 3 ${NODE}" "Strange: Camnode has no eth0 hardware address: $NODE"
}
