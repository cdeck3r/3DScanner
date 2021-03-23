#!/bin/bash
trap cleanup EXIT

#
# Copy files remotely using scp
# Use with ssh keys
#
# Author: cdeck3r
#

# EXAMPLES
#
# Copy nodelist.log from CENTRALNODE IP to local directory
# remote_scp.sh 192.168.178.83 CENTRALNODE pi@192.168.178.83:/home/pi/log/nodelist.log ./
#
# Copy file.txt from local directory to /tmp on CAMNODE IP
# remote_scp.sh 192.168.178.131 CAMNODE ./file.txt pi@192.168.178.83:/tmp
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
NODE=$1     # default
NODETYPE=$2 # default
SRC=$3
DEST=$4
#PI_USER=pi
KEYFILE_DIR=/tmp/autosetup
KEYFILE_ZIP="${SCRIPT_DIR}"/allkeys.zip
USE_SSHPASS=0

#####################################################
# Include Helper functions
#####################################################

usage() {
    echo "Usage: "
    echo "${SCRIPT_NAME} <ip address> <CENTRALNODE | CAMNODE> <src> <dest>"
    echo "Remote src/dest format: <user>@<ip>:<file path>"
}

ssh_login() {
    local SSH_PASS
    local SSH_LOGIN

    if [ "${USE_SSHPASS}" -eq 1 ]; then
        SSH_PASS="sshpass -e"
    else
        SSH_PASS=""
    fi
    SSH_LOGIN="${SSH_PASS} "
    echo "${SSH_LOGIN}"
}

scp_cmd() {
    local keyfile=$1

    SCP_CMD="$(ssh_login) scp -i ${keyfile} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -q"
    echo "${SCP_CMD}"
}

remote_copy() {
    local node=$1
    local keyfile=$2
    local src=$3
    local dest=$4
    local scp_login

    scp_login=$(scp_cmd "${keyfile}")
    scp_remote_cmd="${scp_login} ${src} ${dest}"
    ${scp_remote_cmd}
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
        echo "Derived nodetype unknown: $NODETYPE"
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

# source: https://www.linuxjournal.com/content/validating-ip-address-bash-script
#
# Test an IP address for validity:
# Usage:
#      valid_ip IP_ADDRESS
#      if [[ $? -eq 0 ]]; then echo good; else echo bad; fi
#   OR
#      if valid_ip IP_ADDRESS; then echo good; else echo bad; fi
function valid_ip() {
    local ip=$1
    local stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        # shellcheck disable=SC2206
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && \
        ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

#####################################################
# Main program
#####################################################

### Basic checks ###

# check NODE var
if [ -z "$NODE" ]; then
    echo "No node provided."
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
echo "########### ping ${NODE} ###########"
can_ping "${NODE}"
echo "#################################################"
echo ""

### /Basic checks ###

valid_ip "${NODE}" || {
    echo "IP address not valid: ${NODE}"
    usage
    exit 1
} && {
    # read the NODETYPE as 2nd arg from command line
    if [ -z "${NODETYPE}" ]; then
        echo "No nodetype provided."
        usage
        exit 1
    fi
    NODETYPE=$(echo "${NODETYPE}" | tr '[:lower:]' '[:upper:]')
    if ! [[ "${NODETYPE}" =~ ^(CENTRALNODE|CAMNODE)$ ]]; then
        echo "Nodetype must be one of [CENTRALNODE | CAMNODE]."
        usage
        exit 1
    fi
}

# extract keyfile
keyfile=$(setup_ssh_keyfile "${KEYFILE_ZIP}" "${NODETYPE}")

# run remote copy

# REMOTE --> LOCAL
# SRC: ${PI_USER}@${node}:/home/pi/log/nodelist.log
# DEST: "."

# LOCAL --> REMOTE
# SRC: "./file.txt"
# DEST: ${PI_USER}@${node}:/home/pi

remote_copy "${NODE}" "${keyfile}" "${SRC}" "${DEST}"
cleanup
