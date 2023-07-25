#!/bin/bash
# shellcheck disable=SC1090

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

SKIP_CHECK=$(
    true
    echo $?
)
precheck "${SKIP_CHECK}"

diag "${HR}"
diag "List camera nodes online"
diag "${HR}"

# shellcheck disable=SC2016
TOPIC='scanner/+/$stats/lastupdate'
LAST_UPDATE="mosquitto_sub -v -h ${MQTT_BROKER} -t ${TOPIC} -W 2"
LAST_UPDATE_RES=$(${LAST_UPDATE})
is $? 0 "Retrieve camera nodes update status"
echo "${LAST_UPDATE_RES}" | grep -a lastupdate | cut -d/ -f2,4- | sort

# summary evaluation of camnode lastupdate
diag "${HR}"

LAST_UPDATE_TS=$(echo "${LAST_UPDATE_RES}" | grep -a lastupdate | cut -d/ -f4- | cut -d' ' -f2- | sort | tr " " "_")
mapfile -t LAST_UPDATE_TS_ARRAY < <(echo "${LAST_UPDATE_TS}")

LATE_UPDATE_NODES=0
curr_t_sec=$(date +"%s")

((t_sec_threshold = curr_t_sec - PAST_UPDATE_SEC))
for ts in "${LAST_UPDATE_TS_ARRAY[@]}"; do
    t=$(echo "${ts}" | tr "_" " ")
    # need to swap month and day, because
    # 12/02/2021 17:38:27 is considered as "Dec 2, 2021 17:38:27", but it is
    # Feb 12, 2021 ...
    day=$(echo "${t}" | cut -d'/' -f1)
    month=$(echo "${t}" | cut -d'/' -f2)
    rest=$(echo "${t}" | cut -d'/' -f3-)
    t_swap="${month}/${day}/${rest}"
    # convert in seconds since epoch
    t_sec=$(date -d "${t_swap}" +"%s")
    ((t_sec <= t_sec_threshold)) && { ((LATE_UPDATE_NODES += 1)); }
done
if ((LATE_UPDATE_NODES > 0)); then
    diag "${RED}[FAIL]${NC} - Nodes with no update for at least $((PAST_UPDATE_SEC / 60)) min: ${LATE_UPDATE_NODES}."
else
    diag "${GREEN}[SUCCESS]${NC} - All camera nodes update within $((PAST_UPDATE_SEC / 60)) min."
fi
diag "${HR}"
diag " "

diag "${HR}"
diag "List camera nodes' IP addresses"
diag "${HR}"
# shellcheck disable=SC2016
TOPIC='scanner/+/+'
STATUS_IP_CMD="mosquitto_sub -v -h ${MQTT_BROKER} -t ${TOPIC} -W 2"
STATUS_IP_RES=$(${STATUS_IP_CMD} | tr -d '\0' | sort -u | grep -a camnode | grep -a -E '(\$state|\$localip)')
is $? 0 "Retrieve camera nodes status and IP addresses"
mapfile -t STATUS_IP_ARRAY < <(echo "${STATUS_IP_RES}" | sed -E 's/\s/_/gi' | sed -E '1~2s/(.)$/\1_/gi' | sed -E '2~2s/(.)$/\1#/'| tr -d '\n' | sed -E 's/#/\n/gi')
for camnode in "${STATUS_IP_ARRAY[@]}"; do
    is "$(echo "${camnode}" | cut -d_ -f4)" "ready" "$(echo "${camnode}" | cut -d'_' -f1,2 | tr '_' ' ')"
done
diag " "

