#!/bin/bash

#
# List all recent-image datetime 
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

# error counter 
let err_cnt=0

precheck 1

diag "${HR}"
diag "List all recent-image datetime"
diag "${HR}"
TOPIC='scanner/+/recent-image/datetime'
RECENT_IMAGE_DATETIME="mosquitto_sub -v -h ${MQTT_BROKER} -t ${TOPIC} -W 2"
RECENT_IMAGE_DATETIME_RES=$(${RECENT_IMAGE_DATETIME})
is $? 0 "Retrieve recent image datetime from each camera node"
#echo ${RECENT_IMAGE_DATETIME_RES} | sort

# loop through each camnode and check its recent-image/datetime
diag "Check each recent image datetime"
RECENT_IMAGE_DATETIME_ARRAY=($(echo "${RECENT_IMAGE_DATETIME_RES}" | sort | tr " " "_"))
curr_sec=$(date -d'now' +"%s")
for camnode in "${RECENT_IMAGE_DATETIME_ARRAY[@]}"; do
    cn=$(echo "${camnode}"|cut -d_ -f1)
    dt=$(echo "${camnode}"|cut -d_ -f2)
    dt_sec=$(date -d"${dt}" +"%s")
    
    # dt >= 1 hour 
    # 1 hour > dt >= 12 hours 
    # 12 hour > dt 
    
    let one_hour_old=curr_sec-3600
    let twelve_hours_old=curr_sec-43200
    
    if (( dt_sec >= one_hour_old )); then
        pass "${cn} ${dt}"
    elif (( dt_sec >= twelve_hours_old )); then
        fail "Image not older than 12h - ${cn} ${dt}"
        let err_cnt+=1
    else
        fail "Image older than 12h - ${cn} ${dt}"
        let err_cnt+=1
    fi
done

# summary eval for recent-image datetime
diag "${HR}"
if (( err_cnt == 0 )); then
    diag "${GREEN}[SUCCESS]${NC} - All camnodes provide recent images."
elif (( err_cnt <= 5 )); then
    diag "${YELLOW}[WARNING]${NC} - A few nodes provide old images. Check output."
else
    diag "${RED}[FAIL]${NC} - Severe problem. Several nodes provide old images. Check output."
fi
OLDEST_RECENT_IMAGE_DATETIME=$(echo "${RECENT_IMAGE_DATETIME_RES}" | sort | cut -d/ -f4 | cut -d' ' -f2 | head -1)
if [[ -n "${OLDEST_RECENT_IMAGE_DATETIME}" ]]; then
    diag "${CYAN}[INFO]${NC} - Oldest recent image: ${OLDEST_RECENT_IMAGE_DATETIME}"
fi
diag "${HR}"

