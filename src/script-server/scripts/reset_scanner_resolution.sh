#!/bin/bash
# shellcheck disable=SC1090

#
# Reset all camnode cameras to scanner's default resolutions
# The script publishs a message to 
#   scanner/apparatus/cameras/default-resolution
#
# Author: cdeck3r
#

# Params: None

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

[ -z "${RES_X}" ] && BAIL_OUT "No camera resolution width provided. Abort."
[ -z "${RES_Y}" ] && BAIL_OUT "No camera resolution height provided. Abort."

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
diag "Reset resolution of all scanner cameras"
diag "${HR}"

TOPIC_DEFAULT_RES='scanner/apparatus/cameras/default-resolution/set'

MSG="reset"
DEFAULT_RES_RESET="mosquitto_pub -h ${MQTT_BROKER} -t ${TOPIC_DEFAULT_RES} -m ${MSG}"
${DEFAULT_RES_RESET}
is $? 0 "Scanner resolution reset"

diag "Give some time before starting to verify scanner resolution on all camnodes"
sleep ${YIELD_TIME_SEC}
diag " "

# 
# start other script to check for camnode resolution
#
${SCRIPT_DIR}/check_scanner_resolution.sh

