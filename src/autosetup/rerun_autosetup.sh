#!/bin/bash
set -e

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
NODE=$1 # default
PI_USER=pi
KEYFILE_DIR=/tmp/autosetup
KEYFILE_ZIP="${SCRIPT_DIR}"/allkeys.zip

#####################################################
# Include Helper functions
#####################################################

ssh_cmd() {
    local keyfile=$1

    SSH_CMD="ssh -i ${keyfile} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
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

# check NODE var
if [ -z "$NODE" ]; then
    echo "No node provided. Abort."
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
echo "########### ping ${NODE} ###########"
can_ping "${NODE}"
echo "#################################################"
echo ""

### /Basic checks ###

NODETYPE=$(echo "${NODE}" | cut -d'-' -f1 | tr '[:lower:]' '[:upper:]')
keyfile=$(setup_ssh_keyfile "${KEYFILE_ZIP}" "${NODETYPE}")

# simple hostname test
test_hostname "${NODE}" "${keyfile}"

#rm_booter_done "${NODE}" "${keyfile}"
#shutdown_reboot "${NODE}" "${keyfile}"

cleanup
