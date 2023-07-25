#!/bin/bash
# shellcheck disable=SC1090

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

TOTAL_NODES=0 # default, later retrieved
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

SKIP_CHECK=$(
    false
    echo $?
)
precheck "${SKIP_CHECK}"

diag "${HR}"
diag "Check for scanner's nodes"
diag "${HR}"

# shellcheck disable=SC2016
TOPIC='scanner/+/$stats/lastupdate'
LAST_UPDATE="mosquitto_sub -v -h ${MQTT_BROKER} -t ${TOPIC} -W 2"
LAST_UPDATE_EXE=$(${LAST_UPDATE})
is $? 0 "Search for all camera nodes"
NUM_NODES=$(echo "${LAST_UPDATE_EXE}" | grep -vc apparatus)
((NUM_NODES > 0)) || { fail "No camera nodes found."; }

# shellcheck disable=SC2016
TOPIC='scanner/+/$state'
READY="mosquitto_sub -v -h ${MQTT_BROKER} -t ${TOPIC} -W 2"
READY_EXE=$(${READY})
is $? 0 "Search for all ready nodes"

# loop through each camnode and check its $state
diag "List each ready camera node"
READY_RES=$(echo "${READY_EXE}" | grep -v apparatus)
mapfile -t READY_RES_ARRAY < <(echo "${READY_RES}" | tr " " "_")
for camnode in "${READY_RES_ARRAY[@]}"; do
    is "$(echo "${camnode}" | cut -d_ -f2)" "ready" "$(echo "${camnode}" | tr '_' ' ')"
done

# retrieve TOTAL_NODES
# shellcheck disable=SC2016
# TOPIC='scanner/...'
# TOTAL=
# TOTAL_EXE=$(${TOTAL})
# is $? 0 "Retrieve total number of installed camera nodes"
# TOTAL_RES=

# Summary evaluation of ready camnodes
diag "${HR}"
NUM_READY_NODES=$(echo "${READY_RES}" | grep -c ready)
((NUM_READY_NODES > 0)) || { fail "No camera nodes ready."; }
if ((NUM_READY_NODES >= NUM_NODES_GREEN)); then
    if ((NUM_READY_NODES == TOTAL_NODES)); then
        diag "${GREEN}[SUCCESS]${NC} - All camera nodes ready: ${NUM_READY_NODES}."
    else
        diag "${CYAN}[SUCCESS]${NC} - Camera nodes ready (total: ${TOTAL_NODES}): ${NUM_READY_NODES}."
    fi
elif ((NUM_READY_NODES >= NUM_NODES_YELLOW)); then
    diag "${YELLOW}[WARNING]${NC} - Too few camera nodes ready: ${NUM_READY_NODES}."
else
    diag "${RED}[FAIL]${NC} - Too few camera nodes ready: ${NUM_READY_NODES}."
fi
diag "${HR}"
diag " "

# check scanner/apparatus $state
diag "Check scanner apparatus ready"
READY_RES=$(echo "${READY_EXE}" | grep apparatus)
mapfile -t READY_RES_ARRAY < <(echo "${READY_RES}" | tr " " "_")
for node in "${READY_RES_ARRAY[@]}"; do
    is "$(echo "${node}" | cut -d_ -f2)" "ready" "$(echo "${node}" | tr '_' ' ')"
done

# Summary evaluation of apparatus node
diag "${HR}"
NUM_READY_APPARATUS=$(echo "${READY_RES}" | grep -c ready)
if ((NUM_READY_APPARATUS == 1)); then
    diag "${GREEN}[SUCCESS]${NC} - Scanner apparatus node ready."
else
    diag "${RED}[FAIL]${NC} - Scanner apparatus node lost. Scanner will not work!"
fi
# Check for available disk space - perform housekeeping
./housekeeping.sh
