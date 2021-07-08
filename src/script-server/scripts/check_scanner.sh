#!/bin/bash

#
# Check connection to scanner 
# and test for ready cameras nodes
# 
# Author: cdeck3r
#

# Params: none

# Exit codes
# 0: at the script's end
# 255: if BAIL_OUT

# this directory is the script directory
SCRIPT_DIR="$(
    cd "$(dirname "$0")" || exit
    pwd -P
)"
cd "$SCRIPT_DIR" || exit
# shellcheck disable=SC2034
SCRIPT_NAME=$0


# Vars
MQTT_BROKER="" # set empty

NUM_NODES_GREEN=45
NUM_NODES_YELLOW=35

[ -f "${SCRIPT_DIR}/common_vars.conf" ] || { 
    echo "Could find required config file: common_vars.conf"
    echo "Abort."
    exit 1
}
[ -f "${SCRIPT_DIR}/tap-functions.sh" ] || { 
    echo "Could find required file: tap-functions.sh"
    echo "Abort."
    exit 1
}

source "${SCRIPT_DIR}/common_vars.conf"
source "${SCRIPT_DIR}/tap-functions.sh"

#####################################################
# Include Helper functions
#####################################################

[ -f "${SCRIPT_DIR}/funcs.sh" ] || { 
    echo "Could find required file: funcs.sh"
    echo "Abort."
    exit 1
}
source "${SCRIPT_DIR}/funcs.sh"

#####################################################
# Main program
#####################################################

# first things first
HR=$(hr) # horizontal line
plan_no_plan

SKIP_CHECK=$(false; echo $?)
precheck "${SKIP_CHECK}"

diag "${HR}"
diag "Check for camera nodes"
diag "${HR}"

TOPIC='scanner/+/$stats/lastupdate'
LAST_UPDATE="mosquitto_sub -v -h ${MQTT_BROKER} -t ${TOPIC} -W 2"
LAST_UPDATE_EXE=$( ${LAST_UPDATE} )
is $? 0 "Search for all camera nodes"
NUM_NODES=$( echo "${LAST_UPDATE_EXE}" | grep -v apparatus | wc -l)
(( NUM_NODES > 0 )) || { fail "No camera nodes found."; } 


TOPIC='scanner/+/$state'
READY="mosquitto_sub -v -h ${MQTT_BROKER} -t ${TOPIC} -W 2"
READY_EXE=$( ${READY} )
is $? 0 "Search for all ready camera nodes"
READY_RES=$( echo "${READY_EXE}" | grep -v apparatus )


# loop through each camnode and check its $state
diag "List each ready camera node"
READY_RES_ARRAY=($(echo "${READY_RES}" | tr " " "_"))
for camnode in "${READY_RES_ARRAY[@]}"; do
    is $(echo "${camnode}"|cut -d_ -f2) "ready" "$(echo ${camnode}|tr '_' ' ')"
done

# Summary evaluation of ready camnodes 
diag "${HR}"
NUM_READY_NODES=$( echo "${READY_RES}" | grep -c ready)
(( NUM_READY_NODES > 0 )) || { fail "No camera nodes ready."; }
if (( NUM_READY_NODES >= NUM_NODES_GREEN )); then
    diag "${GREEN}[SUCCESS]${NC} - Camera nodes ready: ${NUM_READY_NODES}."
elif (( NUM_READY_NODES >= NUM_NODES_YELLOW )); then
    diag "${YELLOW}[WARNING]${NC} - Too few camera nodes ready: ${NUM_READY_NODES}."
else
    diag "${RED}[FAIL]${NC} - Too few camera nodes ready: ${NUM_READY_NODES}."
fi
diag "${HR}"
