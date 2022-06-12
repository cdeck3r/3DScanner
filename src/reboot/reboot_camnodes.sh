#!/bin/bash
set -e

#
# CAMNODES reboot
# Reboots all camnodes
#

# Params: none

# Exit codes
# 1 - if precond not satisfied
# 2 - if other things break

# this directory is the script directory
SCRIPT_DIR="$(
    cd "$(dirname "$0")" || exit
    pwd -P
)"
cd "$SCRIPT_DIR" || exit
# shellcheck disable=SC2034
SCRIPT_NAME=$0

# variables
USER="pi"
USER_HOME="/home/${USER}"                       # default: /home/pi
SCANODIS_SH="${USER_HOME}/scanodis/scanodis.sh" # exists on centralnode
NODELIST="${USER_HOME}/log/nodelist.log"        # exists on centralnode
REBOOT_DELAY=5                                  # default: 5min delay between two node's reboot
export REBOOT_DELAY

#####################################################
# Include Helper functions
#####################################################

# begin of function export
set -a
# shellcheck disable=SC1090
source "${SCRIPT_DIR}/funcs.sh"
set +a
# end of function export

# verfies the script runs as ${USER}
check_user() {
    local CURR_USER

    CURR_USER=$(id --user --name)
    if [ "${CURR_USER}" != "${USER}" ]; then
        return 1
    fi

    return 0
}

# check that script files exists and
# is executable
check_script() {
    local script_file=$1

    [[ -f "${script_file}" ]] || {
        log_echo "ERROR" "Script not found: ${script_file}"
        return 1
    }
    [[ -x "${script_file}" ]] || {
        log_echo "ERROR" "Script not executable: ${script_file}"
        return 1
    }

    return 0
}

# begin of function export
set -a
ssh_cmd() {
    SSH_CMD="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -q"
    echo "${SSH_CMD}"
}

shutdown_reboot() {
    local node=$1
    local delay=$2
    local ssh_login

    ssh_login=$(ssh_cmd)
    ssh_reboot="${ssh_login} -t ${USER}@${node} sudo shutdown -r ${delay}"
    ${ssh_reboot}
}

set_powersave() {
    local node=$1
    local ssh_login

    ssh_login=$(ssh_cmd)
    ssh_set_powersave="${ssh_login} -t ${USER}@${node} echo powersave | sudo tee /sys/devices/system/cpu/cpufreq/policy0/scaling_governor >/dev/null"
    ${ssh_set_powersave}
}

stop_homie_camnode() {
    local node=$1
    local ssh_login
    local remote_user_id
    local stop_cmd

    # if on centralnode, do nothing, otherwise disable homie_camnode service
    remote_user_id="id -u ${USER}"
    stop_cmd="hostname | grep -qi centralnode || export XDG_RUNTIME_DIR=/run/user/$(${remote_user_id}) && systemctl --user is-active --quiet homie_camnode.service; if [ \$? -eq 0 ]; then systemctl --user stop homie_camnode.service; else echo 'WARN: homie_camnode.service not active. No action required.'; fi"

    ssh_login=$(ssh_cmd)
    ssh_stop_homie_camnode="${ssh_login} -t ${USER}@${node} ${stop_cmd}"
    # shellcheck disable=SC2090
    ${ssh_stop_homie_camnode}
}

switch_off_LED() {
    local node=$1
    local ssh_login
    local switch_off_cmd

    switch_off_cmd="if [ -f /boot/autosetup/3DScanner/src/blink/blink.sh ]; then /boot/autosetup/3DScanner/src/blink/blink.sh none; else echo 'WARN: blink.sh not found.'; fi"

    ssh_login=$(ssh_cmd)
    ssh_switch_off_LED="${ssh_login} -t ${USER}@${node} ${switch_off_cmd}"
    # shellcheck disable=SC2090
    ${ssh_switch_off_LED}
}

reboot_node_in_minutes() {
    local node_num=$1
    local node_addr=$2
    local delay

    delay=$((node_num * REBOOT_DELAY))
    log_echo "INFO" "Reboot node ${node_addr} in ${delay} minutes"
    {
        log_echo "INFO" "Stop homie service on node: ${node_addr}" &&
            stop_homie_camnode "${node_addr}" &&
            log_echo "INFO" "Switch off green LED on node: ${node_addr}" &&
            switch_off_LED "${node_addr}" &&
            log_echo "INFO" "Set powersave on node: ${node_addr}" &&
            set_powersave "${node_addr}" &&
            log_echo "INFO" "Enqueue reboot on node: ${node_addr}" &&
            shutdown_reboot "${node_addr}" "${delay}"
    } || {
        log_echo "ERROR" "Could not enqueue reboot for node ${node_addr}"
        exit 2
    }
}
# end of function export
set +a

# outputs a json array containing all camnodes from NODELIST
nodelist_as_json() {
    local nodelist_json

    # log nodelist as json
    # src: https://stackoverflow.com/questions/44780761/converting-csv-to-json-in-bash/65100738#65100738
    nodelist_json=$( (echo "Hostname,IP" && sort -u "${NODELIST}" | tr '\t' ',') | python3 -c 'import csv, json, sys; print(json.dumps([dict(r) for r in csv.DictReader(sys.stdin)]))')
    echo "${nodelist_json}"
}

#####################################################
# Main program
#####################################################

# basic checks
assert_on_raspi
assert_on_centralnode

check_user || {
    log_echo "ERROR" "User mismatch. Script must run as user: ${USER}. Abort."
    exit 1
}

# indicate start
log_echo "INFO" "Start rebooting all camnodes."
# Check: NODELIST
[[ -f "${NODELIST}" ]] || {
    log_echo "ERROR" "Nodelist not found: ${NODELIST}"
    exit 2
}
# log count
NODELIST_NODE_COUNT=$(sort -u "${NODELIST}" | wc -l)
log_echo "INFO" "BEFORE REBOOT - number of camnodes: ${NODELIST_NODE_COUNT}"
if ((NODELIST_NODE_COUNT < 1)); then
    log_echo "ERROR" "Too few camnodes: ${NODELIST_NODE_COUNT} - Abort."
    exit 2
fi

# log nodelist as json
log_echo "INFO" "$(nodelist_as_json)"

# call bash function 'reboot_node_in_minutes' for each node from NODELIST
sort -u "${NODELIST}" | cat -b | cut -d$'\t' -f1,3 | xargs -n2 bash -c 'reboot_node_in_minutes "$@"' _

exit 0

# run after NODELIST_NODE_COUNT * REBOOT_DELAY
# plus another REBOOT_DELAY to give time for the last reboot
POST_REBOOT_TIME=$(((NODELIST_NODE_COUNT + 1) * REBOOT_DELAY))
log_echo "INFO" "Next activitiy starts in ${POST_REBOOT_TIME} minutes"
sleep "${POST_REBOOT_TIME}"m

# Post reboot checks
check_script "${SCANODIS_SH}" || { exit 1; }
log_echo "INFO" "Run scanodis twice"
"${SCANODIS_SH}" || { log_echo "WARN" "scanodis returned an error. Check log."; }
"${SCANODIS_SH}" || { log_echo "WARN" "scanodis returned an error. Check log."; }

# log count
NODELIST_NODE_COUNT=$(sort -u "${NODELIST}" | wc -l)
log_echo "INFO" "AFTER REBOOT - number of camnodes: ${NODELIST_NODE_COUNT}"
log_echo "INFO" "$(nodelist_as_json)"

exit 0
