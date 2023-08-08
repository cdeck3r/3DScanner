#!/bin/bash
# shellcheck disable=SC1090

#
# Reads scanner resolutions from 
#   scanner/apparatus/cameras/resolution-x
#   scanner/apparatus/cameras/resolution-y
#
# Reads all camnodes' resolutions from 
#   scanner/+/camera/resolution-x
#   scanner/+/camera/resolution-y
#
# Compares 
#   each camnode's x value with scanner's x value
#   each camnode's y value with scanner's y value
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
diag "Check scanner resolution on all camnodes"
diag "${HR}"
# shellcheck disable=SC2016
TOPIC='scanner/apparatus/cameras/resolution-x'
RES_X="mosquitto_sub -v -h ${MQTT_BROKER} -t ${TOPIC} -W 2"
SCANNER_RES_X=$(${RES_X} | cut -d' ' -f2)
is $? 0 "Retrieve scanner's resolution width"

TOPIC='scanner/apparatus/cameras/resolution-y'
RES_Y="mosquitto_sub -v -h ${MQTT_BROKER} -t ${TOPIC} -W 2"
SCANNER_RES_Y=$(${RES_Y} | cut -d' ' -f2)
is $? 0 "Retrieve scanner's resolution height"

((SCANNER_RES_X > 0)); ok $? "Scanner resolution width: ${SCANNER_RES_X}"
((SCANNER_RES_Y > 0)); ok $? "Scanner resolution height: ${SCANNER_RES_Y}"

diag "${HR}"
diag "Retrieve resolution of all camnodes"
diag "${HR}"

TOPIC='scanner/+/camera/resolution-x'
RES_X="mosquitto_sub -v -h ${MQTT_BROKER} -t ${TOPIC} -W 2"
CAMNODE_RES_X=$(${RES_X})
is $? 0 "Retrieve camnodes' resolution width"

TOPIC='scanner/+/camera/resolution-y'
RES_Y="mosquitto_sub -v -h ${MQTT_BROKER} -t ${TOPIC} -W 2"
CAMNODE_RES_Y=$(${RES_Y})
is $? 0 "Retrieve camnodes' resolution height"

mapfile -t CAMNODE_RES_X_ARRAY < <(echo "${CAMNODE_RES_X}" | tr " " "_")
mapfile -t CAMNODE_RES_Y_ARRAY < <(echo "${CAMNODE_RES_Y}" | tr " " "_")

res_error_cnt=0
for camnode_res in "${CAMNODE_RES_X_ARRAY[@]}"; do
    is "$(echo "${camnode_res}" | cut -d_ -f2)" "${SCANNER_RES_X}" "$(echo "${camnode_res}" | tr '_' ' ')"
    if [ $? -ne 0 ]; then 
        ((res_error_cnt = res_error_cnt+1))
    fi
done

for camnode_res in "${CAMNODE_RES_Y_ARRAY[@]}"; do
    is "$(echo "${camnode_res}" | cut -d_ -f2)" "${SCANNER_RES_Y}" "$(echo "${camnode_res}" | tr '_' ' ')"
    if [ $? -ne 0 ]; then 
        ((res_error_cnt = res_error_cnt+1))
    fi
done


# Summary
diag "${HR}"
((res_error_cnt > 0)) && { diag "${RED}[FAIL]${NC} - Resolution mismatch between scanner and camnode. Check previous output."; }
((res_error_cnt == 0)) && { diag "${GREEN}[SUCCESS]${NC} - Scanner resolution matches all camnodes."; }
diag "${HR}"
