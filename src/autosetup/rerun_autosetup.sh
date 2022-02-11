#!/bin/bash

set -e
trap cleanup EXIT

#
# Re-runs the autosetup
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
NODEIP=${1:-1.2.3.4}
NODETYPE=$2
PI_USER=pi
KEYFILE_DIR=/tmp/autosetup
KEYFILE_ZIP="${SCRIPT_DIR}"/allkeys.zip

#####################################################
# Include Helper functions
#####################################################

usage() {
    echo "Usage: ${SCRIPT_NAME} <IP> <CENTRALNODE|CAMNODE>"
}

#
# assert docker
# we expect the script to execute within the docker container
assert_in_docker() {
    # Src: https://stackoverflow.com/a/20012536
    grep -Eq '/(lxc|docker)/[[:xdigit:]]{64}' /proc/1/cgroup || {
        echo "ERROR: Please run this script in docker container"
        exit 1
    }
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

ssh_cmd() {
    local keyfile=$1

    SSH_CMD="ssh -i ${keyfile} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -q"
    echo "${SSH_CMD}"
}

shutdown_reboot() {
    local node=$1
    local keyfile=$2
    local ssh_login

    ssh_login=$(ssh_cmd "${keyfile}")
    ssh_reboot="${ssh_login} -t ${PI_USER}@${node} sudo shutdown -r now"
    ${ssh_reboot}
}

rm_booter_done() {
    local node=$1
    local keyfile=$2
    local ssh_login

    ssh_login=$(ssh_cmd "${keyfile}")
    ssh_rm_booter_done="${ssh_login} -t ${PI_USER}@${node} sudo rm -rf /boot/booter.done"
    ${ssh_rm_booter_done}
}

deploy_autosetup_zip() {
    local node=$1
    local keyfile=$2
    local ssh_login

    ssh_login=$(ssh_cmd "${keyfile}")

    # validate: X in autosetup_Xnode.zip -> X == nodetype?
    # cp autosetup_Xnode.zip /boot

    ## SHOW STOPPER ##
    # autosetup_Xnode.zip contains new keyfile (therfore, allkeys.zip as well)
    # deployment must use old keyfile to succeed

}

can_ping() {
    local node=$1
    ping -c 3 "${node}" || {
        echo "Cannot ping node $node"
        exit 1
    }
}

setup_ssh_keyfile() {
    local keyfile_zip=$1
    local nodetype=$2
    local keyfile

    if [ "${nodetype}" = "CAMNODE" ]; then
        keyfile="${KEYFILE_DIR}/camnode.priv"
    elif [ "${nodetype}" = "CENTRALNODE" ]; then
        keyfile="${KEYFILE_DIR}/centralnode.priv"
    else
        echo "Nodetype unknown: $NODETYPE"
        exit 1
    fi

    uid=$(id --user)
    gid=$(id --group)

    # unzip keyfile
    [ -f "${keyfile_zip}" ] || {
        echo "Could not find file: ${keyfile_zip}"
        exit 1
    }
    [ "${KEYFILE_DIR}" == "${SCRIPT_DIR}" ] && {
        echo "Something is wrong. KEYFILE_DIR is the same as SCRIPT_DIR."
        exit 1
    }

    rm -rf "${KEYFILE_DIR}"
    unzip -qq "${keyfile_zip}" -d "${KEYFILE_DIR}"

    [ -f "${keyfile}" ] || {
        echo "Keyfile does not exist: $keyfile"
        exit 1
    }

    # set appropriate permissions
    chmod 700 "${KEYFILE_DIR}"
    chown "${uid}":"${gid}" "${KEYFILE_DIR}"

    chmod 600 "${keyfile}"
    chown "${uid}":"${gid}" "${keyfile}"

    echo "${keyfile}"
}

cleanup() {
    rm -rf "${KEYFILE_DIR}"
}

### Test function ###
test_hostname() {
    local node=$1
    local keyfile=$2
    local ssh_login

    ssh_login=$(ssh_cmd "${keyfile}")
    ssh_hostname="${ssh_login} -t ${PI_USER}@${node} hostname"
    echo "Run command: "
    echo "${ssh_hostname}"

    ${ssh_hostname}
}
### Test function ###

#####################################################
# Main program
#####################################################

### Basic checks ###
assert_in_docker # only works in DEV system

[ "$#" -eq 2 ] || {
    echo "Too few arguments."
    usage
    exit 1
}
# validate IP address
valid_ip "${NODEIP}" || {
    echo "IP address is not valid: ${NODEIP}"
    usage
    exit 1
}
# check NODETYPE var
if ! [[ "${NODETYPE}" =~ ^(CENTRALNODE|CAMNODE)$ ]]; then
    echo "Invalid nodetype provided."
    usage
    exit 1
fi

# check tools
TOOLS=('ping' 'unzip' 'tr')
for t in "${TOOLS[@]}"; do
    command -v "${t}" >/dev/null || {
        echo "Could not find tool: $t"
        exit 1
    }
done

echo ""
echo "########### ping ${NODEIP} ###########"
can_ping "${NODEIP}"
echo "#################################################"
echo ""

### /Basic checks ###

keyfile=$(setup_ssh_keyfile "${KEYFILE_ZIP}" "${NODETYPE}")

echo "Restart ${NODETYPE} with ${NODEIP}"
rm_booter_done "${NODEIP}" "${keyfile}" || {
    echo "Error when deleting booter.done on ${NODEIP}."
    exit 2
}
shutdown_reboot "${NODEIP}" "${keyfile}" || {
    echo "Error issuing reboot on ${NODEIP}."
    exit 2
}
echo "Successfully restarted ${NODETYPE} with ${NODEIP}"

cleanup
