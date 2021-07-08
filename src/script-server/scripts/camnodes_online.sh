#!/bin/bash

#
# Lists all online camnodes
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
PAST_UPDATE_SEC=300 # lastupdate is max. 5min in the past


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

SKIP_CHECK=$(true; echo $?)
precheck "${SKIP_CHECK}"


diag "${HR}"
diag "List camera nodes online"
diag "${HR}"

TOPIC='scanner/+/$stats/lastupdate'
LAST_UPDATE="mosquitto_sub -v -h ${MQTT_BROKER} -t ${TOPIC} -W 2"
LAST_UPDATE_RES=$(${LAST_UPDATE})
is $? 0 "Retrieve camera nodes update status"
echo "${LAST_UPDATE_RES}" | grep -a lastupdate | cut -d/ -f2,4- | sort

# summary evaluation of camnode lastupdate
diag "${HR}"

LAST_UPDATE_TS=$(echo "${LAST_UPDATE_RES}" | grep -a lastupdate | cut -d/ -f4- | cut -d' ' -f2- | sort | tr " " "_")
LAST_UPDATE_TS_ARRAY=($(echo "${LAST_UPDATE_TS}"))
LATE_UPDATE_NODES=0
curr_t_sec=$(date +"%s")

let t_sec_threshold=curr_t_sec-PAST_UPDATE_SEC
for ts in "${LAST_UPDATE_TS_ARRAY[@]}"; do
    t=$(echo ${ts} | tr "_" " ")
    # need to swap month and day, because 
    # 06/07/2021 17:38:27 is considered as "Jun 7, 2021 17:38:27"
    t_swap=$(date -d "${t}" +"%d/%m/%Y %H:%M:%S")
    # convert in seconds since epoch
    t_sec=$(date -d "${t_swap}" +"%s")
    (( t_sec <= t_sec_threshold )) && { let LATE_UPDATE_NODES+=1; }
done
if (( LATE_UPDATE_NODES > 0 )); then
    diag "${RED}[FAIL]${NC} - Nodes with no update for at least $((PAST_UPDATE_SEC/60)) min: ${LATE_UPDATE_NODES}."
else
    diag "${GREEN}[SUCCESS]${NC} - All camera nodes update within $((PAST_UPDATE_SEC/60)) min."
fi

diag "${HR}"

