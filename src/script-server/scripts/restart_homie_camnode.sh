#!/bin/bash
# shellcheck disable=SC1090

#
# Restarts the homie camnode service
# This is necessary to fully rebuild the camnode's
# connection after the centralnode had restarted.
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
PI_USER=pi
NODELIST_LOG="/home/${PI_USER}/log/nodelist.log"
FAILED_RESTART_YELLOW=5 # WARNING threshold for failed restart
SET_SCALING_GOVERNOR_DISABLE=true
CURR_SCALING_GOVERNOR="unknown"

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

# returns the current scaling_governor 
# setting from given node
read_scaling_governor() {
    local node=$1
    local ssh_login
    local curr_scaling_governor
    local curr_scaling_governor_cmd
    
    curr_scaling_governor="unknown"
    ssh_login="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -q"
    curr_scaling_governor_cmd="cat /sys/devices/system/cpu/cpufreq/policy0/scaling_governor"

    ssh_curr_scaling_governor="${ssh_login} -t ${PI_USER}@${node} ${curr_scaling_governor_cmd}"
    curr_scaling_governor=$(${ssh_curr_scaling_governor})
    ok $? "Reading current power management from ${node}"

    CURR_SCALING_GOVERNOR="${curr_scaling_governor}"
}


#####################################################
# Main program
#####################################################

# first things first
HR=$(hr) # horizontal line
plan_no_plan

# error counter
((err_cnt = 0))

SKIP_CHECK=$(
    true
    echo $?
)
precheck "${SKIP_CHECK}"

diag "${HR}"
diag "Collect camnodes from nodelist"
diag "${HR}"

[ -f "${NODELIST_LOG}" ] || { BAIL_OUT "File not found: ${NODELIST_LOG}"; }
mapfile -t CAMNODE_IP_ARRAY < <(cat "${NODELIST_LOG}" | sort | uniq | cut -d$'\t' -f2)
is $? 0 "Read IP addresses from nodelist"
isnt "${#CAMNODE_IP_ARRAY[@]}" 0 "IP addresses available"

diag " "

diag "${HR}"
diag "Remotely restart homie camnode service"
diag "${HR}"

SSH_LOGIN="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -q"
REMOTE_USER_ID="id -u ${PI_USER}"
RESTART_CMD="XDG_RUNTIME_DIR=/run/user/$(${REMOTE_USER_ID}) systemctl --user restart homie_camnode.service"

SET_SCALING_ONDEMAND="echo ondemand | sudo tee /sys/devices/system/cpu/cpufreq/policy0/scaling_governor >/dev/null"

for camnode in "${CAMNODE_IP_ARRAY[@]}"; do
    diag "Try to restart ${camnode}..."

    ((trial_cnt = 3))
    while ((--trial_cnt > 0)); do
        ssh_restart_service="${SSH_LOGIN} -t ${PI_USER}@${camnode} ${RESTART_CMD}"
        okx "${ssh_restart_service}" && { break; }
        #(( $? == 0 ))
    done
    # counter shall not be 0 to indicate success, otherwise inc err_cnt
    isnt ${trial_cnt} 0 "Restart service on ${camnode}"
    ((trial_cnt == 0)) && { ((err_cnt += 1)); continue; }

    # set scaling governor to "ondemand"
    diag "Test and set power management for ${camnode}..."
    
    # 1. Read current scaling_governor
    # 2. Test scaling for "powersave"
    # 3. Set scaling_governor to "ondemand"
    read_scaling_governor "${camnode}" || { continue; } # will set global var CURR_SCALING_GOVERNOR
    is "${CURR_SCALING_GOVERNOR}" "powersave" "Current power management on ${camnode}: ${CURR_SCALING_GOVERNOR}"

    test "${SET_SCALING_GOVERNOR_DISABLE}" == true
    skip $? "Modify power management is disabled for ${camnode}" || {
        ssh_set_scaling_ondemand="${SSH_LOGIN} -t ${PI_USER}@${camnode} ${SET_SCALING_ONDEMAND}"
        ${ssh_set_scaling_ondemand}
        ok $? "Set power management for ${camnode}: ondemand" || { true; }
    }

done

# Summary evaluation of ready camnodes
diag "${HR}"
if ((err_cnt == 0)); then
    diag "${GREEN}[SUCCESS]${NC} - All camnodes services restarted: ${#CAMNODE_IP_ARRAY[@]} camera nodes"
elif ((err_cnt <= FAILED_RESTART_YELLOW)); then
    diag "${YELLOW}[WARNING]${NC} - Few camnode services failed to restart: ${err_cnt} failed restarts"
else
    diag "${RED}[FAIL]${NC} - Significant number of camnode services failed to restart: ${err_cnt} failed restarts"
fi
diag "${HR}"

# Set all camnodes' resolution to the scanner's ones 
diag "${HR}"
diag "Set camnode resolution to match scanner" 
diag "${HR}"
# This is a two-step approach
# 1. Read scanner's current resolution
# 2. Set the same resolution again to propagate to all camnodes

# Step 1 ###################
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

# give some time
sleep(2)

# Step 2 ###################
TOPIC_RES_X='scanner/apparatus/cameras/resolution-x/set'
TOPIC_RES_Y='scanner/apparatus/cameras/resolution-y/set'

MSG_RES_X="${SCANNER_RES_X}"
MSG_RES_Y="${SCANNER_RES_Y}"
RES_SET="mosquitto_pub -h ${MQTT_BROKER} -t ${TOPIC_RES_X} -m ${MSG_RES_X}"
${RES_SET}
is $? 0 "Resolution width set"
RES_SET="mosquitto_pub -h ${MQTT_BROKER} -t ${TOPIC_RES_Y} -m ${MSG_RES_Y}"
${RES_SET}
is $? 0 "Resolution height set"

diag "Give some time before starting to verify scanner resolution on all camnodes"
sleep ${YIELD_TIME_SEC}
diag " "

# 
# start other script to check for camnode resolution
#
${SCRIPT_DIR}/check_scanner_resolution.sh
