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

    echo curr_scaling_governor
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
    ((trial_cnt == 0)) && { ((err_cnt += 1)); }

    # set scaling governor to "ondemand"
    diag "Test and set power management for ${camnode}..."
    
    # 1. Read current scaling_governor
    # 2. Test scaling for "powersave"
    # 3. Set scaling_governor to "ondemand"
    CURR_SCALING_GOVERNOR=$(read_scaling_governor "${camnode}")
    is "${CURR_SCALING_GOVERNOR}" "powersave" "Current power management on ${camnode}: ${CURR_SCALING_GOVERNOR}"

    test "${SET_SCALING_GOVERNOR_DISABLE}" == true
    skip $? "Modify power management is disabled for ${camnode}" || {
        ssh_set_scaling_ondemand="${SSH_LOGIN} -t ${PI_USER}@${camnode} ${SET_SCALING_ONDEMAND}"
        ${ssh_set_scaling_ondemand}
        ok $? "Set power management for ${camnode}: ondemand"
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
