#!/bin/bash

set -e

#
# let a node speficied by its IP address; runs on CENTRALNODE only
#
# Author: cdeck3r
#

# Params: none

# Exit codes
# >0 if script breaks

# this directory is the script directory
SCRIPT_DIR="$(
    cd "$(dirname "$0")" || exit
    pwd -P
)"
cd "$SCRIPT_DIR" || exit
# shellcheck disable=SC2034
SCRIPT_NAME=$0

# variables
NODEIP=$1
BLINK_PATTERN=$2
ALLOWED_PATTERN=""
BLINK_SH="${SCRIPT_DIR}/blink.sh"
USER=pi
NODELIST="/home/${USER}/log/nodelist.log"
PING_ENABLED=1

#####################################################
# Include Helper functions
#####################################################

[ -f "${SCRIPT_DIR}/funcs.sh" ] || {
    echo "Could find required file: funcs.sh"
    echo "Abort."
    exit 1
}
# shellcheck disable=SC1090
source "${SCRIPT_DIR}/funcs.sh"

usage() {
    echo "Usage: ${SCRIPT_NAME} <IP|all> [pattern]"
    echo ""
    echo "Arguments:"
    echo "IP      - IPv4 address or"
    echo "        - \"all\" to let all known camnodes blink"
    echo "pattern - blink pattern"
    echo ""
    echo "Allowed pattern:"
    echo "${ALLOWED_PATTERN}"
}

valid_ip() {
    local ip=$1
    local re

    re='^(0*(1?[0-9]{1,2}|2([0-4][0-9]|5[0-5]))\.){3}'
    re+='0*(1?[0-9]{1,2}|2([‌​0-4][0-9]|5[0-5]))$'

    if [[ $ip =~ $re ]]; then
        return 0
    else
        return 1
    fi
}

# verfies the script runs as ${USER}
check_user() {
    local CURR_USER

    CURR_USER=$(id --user --name)
    if [ "${CURR_USER}" != "${USER}" ]; then
        return 1
    fi

    return 0
}

ssh_base() {
    local SSH_CMD

    SSH_CMD="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -q"
    echo "${SSH_CMD}"
}
ssh_login() {
    local node=$1
    local SSH_CMD

    SSH_CMD="$(ssh_base) -t ${USER}@${node}"
    echo "${SSH_CMD}"
}

ssh_cmd() {
    local node=$1
    local cmd=$2
    local SSH_CMD

    SSH_CMD="$(ssh_login "${node}") ${cmd}"
    ${SSH_CMD}
}

can_ping() {
    local node=$1

    [[ PING_ENABLED -eq 1 ]] && {
        echo ""
        echo "########### ping ${node} ###########"
        ping -c 3 "${node}" || {
            echo "Cannot ping node $node"
            exit 1
        }
        echo "#################################################"
        echo ""
    }

}

blink_node() {
    local nodeip=$1
    local blink_pattern=$2
    local blink_cmd

    blink_cmd="${BLINK_SH} ${blink_pattern}"
    ssh_cmd "${nodeip}" "${blink_cmd}"
}

#####################################################
# Main program
#####################################################

### Basic checks ###
assert_on_raspi
# check we are on CENTRALNODE
assert_on_centralnode

# check for blink program
[[ -f "${BLINK_SH}" ]] || {
    log_echo "ERROR" "Could not find file: ${BLINK_SH}"
    exit 1
}
ALLOWED_PATTERN=$(grep "ALLOWED_PATTERN=" "${BLINK_SH}" | cut -d'=' -f2)

check_user || {
    log_echo "ERROR" "User mismatch. Script must run as user: ${USER}. Abort."
    exit 1
}
# validate IP
[[ "${NODEIP}" == "all" ]] || {
    # validate IP address
    valid_ip "${NODEIP}" || {
        echo "IP address is not valid: ${NODEIP}"
        usage
        exit 1
    }
}
[[ -z "${BLINK_PATTERN}" ]] && { BLINK_PATTERN=""; }

# check tools
TOOLS=('ping' 'ssh' 'cut' 'sort')
for t in "${TOOLS[@]}"; do
    command -v "${t}" >/dev/null || {
        log_echo "ERROR" "Could not find tool: $t"
        exit 1
    }
done

### /Basic checks ###

if [[ "${NODEIP}" == "all" ]]; then
    # override PING_ENABLED to deactivate the ping test
    PING_ENABLED=0
    log_echo "INFO" "PING_ENABLED override. Will not ping the node IP. PING_ENABLED=${PING_ENABLED}"

    [[ -f "${NODELIST}" ]] || {
        log_echo "ERROR" "File with camnode IP addresses not found: ${NODELIST}"
        exit 2
    }

    log_echo "INFO" "Read node list: ${NODELIST}"
    NODE_RES=$(sort -u "${NODELIST}" | cut -d$'\t' -f2)
    mapfile -t NODE_RES_ARRAY < <(echo "${NODE_RES}")
    log_echo "INFO" "Will ping all nodes. Total number: ${#NODE_RES_ARRAY[@]}"
    for ip in "${NODE_RES_ARRAY[@]}"; do
        log_echo "INFO" "Send blink pattern to node ${ip}"
        blink_node "${ip}" "${BLINK_PATTERN}" || { log_echo "ERROR" "Problem when sending blink pattern to node: ${ip}"; }
    done

else
    can_ping "${NODEIP}"
    log_echo "INFO" "Send blink pattern to node ${NODEIP}"
    blink_node "${NODEIP}" "${BLINK_PATTERN}" || { log_echo "ERROR" "Problem when sending blink pattern to node: ${ip}"; }
fi
