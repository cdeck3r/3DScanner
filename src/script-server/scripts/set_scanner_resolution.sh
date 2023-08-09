#!/bin/bash
# shellcheck disable=SC1090

#
# Set all camnode cameras to scanner's resolutions
# The script publishs a message to 
#   scanner/apparatus/cameras/resolution-x
#   scanner/apparatus/cameras/resolution-y
#
# Author: cdeck3r
#

# Params: 
#   X x Y resolution in pixel
#   "reset" or empty to request a reset
RES_XY=$1
RES_RESET=$2

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
YIELD_TIME_SEC=4 # time to wait before checking camnode resolution
MQTT_BROKER="" # set empty

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
    true
    echo $?
)
precheck "${SKIP_CHECK}"

diag "${HR}"
diag "Parameter check"
diag "${HR}"

[ -z "${RES_XY}" ] && BAIL_OUT "No camera resolution provided. Abort."
[ -z "${RES_XY}" ] || pass "Camera resolution provided: ${RES_XY}"
[ -z "${RES_RESET}" ] || pass "Reset requested. Will ignore camera resolution."

if [ -z "${RES_RESET}" ]; then
    # set resolution
    diag "${HR}"
    diag "Set resolution of all scanner cameras"
    diag "${HR}"

    RES_X=$(echo "${RES_XY}" | cut -d' ' -f1)
    RES_Y=$(echo "${RES_XY}" | cut -d' ' -f3)

    TOPIC_RES_X='scanner/apparatus/cameras/resolution-x/set'
    TOPIC_RES_Y='scanner/apparatus/cameras/resolution-y/set'

    MSG_RES_X="${RES_X}"
    MSG_RES_Y="${RES_Y}"
    RES_SET="mosquitto_pub -h ${MQTT_BROKER} -t ${TOPIC_RES_X} -m ${MSG_RES_X}"
    ${RES_SET}
    is $? 0 "Resolution width set"
    RES_SET="mosquitto_pub -h ${MQTT_BROKER} -t ${TOPIC_RES_Y} -m ${MSG_RES_Y}"
    ${RES_SET}
    is $? 0 "Resolution height set"

elif [ "${RES_RESET}" == "reset" ]; then
    # reset
    diag "${HR}"
    diag "Reset resolution of all scanner cameras"
    diag "${HR}"

    TOPIC_DEFAULT_RES='scanner/apparatus/cameras/default-resolution/set'

    MSG="${RES_RESET}"
    DEFAULT_RES_RESET="mosquitto_pub -h ${MQTT_BROKER} -t ${TOPIC_DEFAULT_RES} -m ${MSG}"
    ${DEFAULT_RES_RESET}
    is $? 0 "Scanner resolution reset"
fi

diag "Give some time before starting to verify scanner resolution on all camnodes"
sleep ${YIELD_TIME_SEC}
diag " "
# Check Scanner resolution on all camnodes
${SCRIPT_DIR}/check_scanner_resolution.sh
diag " "