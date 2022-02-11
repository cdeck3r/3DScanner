#!/bin/bash
trap cleanup EXIT

#
# Remotely starts a bash shell on the given node
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
NODE=$1       # default
NODETYPE=$2   # default
REMOTE_CMD=$3 # default
PI_USER=pi
KEYFILE_DIR=/tmp/autosetup
KEYFILE_ZIP="${SCRIPT_DIR}"/allkeys.zip
USE_SSHPASS=0

#####################################################
# Include Helper functions
#####################################################

usage() {
    echo "Usage: "
    echo "${SCRIPT_NAME} <nodename> [command]"
    echo "${SCRIPT_NAME} <ip address> [CENTRALNODE | CAMNODE] [command]"
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

test_ssh_login() {
    local node=$1
    local keyfile=$2

    USE_SSHPASS=1
    # some checks first
    # shellcheck disable=SC2153
    if [ -z "${SSHPASS}" ]; then
        echo "Env var SSHPASS not set. Please set variable."
    else
        ssh_hostname="$(ssh_cmd /dev/null) -t ${PI_USER}@${node} hostname"
        ${ssh_hostname} >/dev/null && {
            echo "Login successful. USE_SSHPASS: ${USE_SSHPASS}"
            return 0
        }
    fi

    # test with USE_SSHPASS=0
    USE_SSHPASS=0
    ssh_hostname="$(ssh_cmd "${keyfile}") -t ${PI_USER}@${node} hostname"
    ${ssh_hostname} >/dev/null && {
        echo "Login successful using ssh keys. USE_SSHPASS: ${USE_SSHPASS}"
        return 0
    } || {
        echo "Login does not work. USE_SSHPASS: ${USE_SSHPASS}"
        return 1
    }
}

ssh_cmd() {
    local keyfile=$1

    SSH_CMD="$(ssh_login) ssh -i ${keyfile} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -q"
    echo "${SSH_CMD}"
}

remote_bash_shell() {
    local node=$1
    local keyfile=$2
    local remote_command=$3
    local ssh_login

    ssh_login=$(ssh_cmd "${keyfile}")
    ssh_remote_shell_cmd="${ssh_login} -t ${PI_USER}@${node} ${remote_command}"
    ${ssh_remote_shell_cmd}
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
    NODETYPE=$(echo "${NODE}" | cut -d'-' -f1 | tr '[:lower:]' '[:upper:]')
    # read the REMOTE_CMD as 2nd arg from command line
    REMOTE_CMD=$2
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
keyfile=$(setup_ssh_keyfile "${KEYFILE_ZIP}" "${NODETYPE}")

# test login
# 1. providing password using sshpass
# 2. if 1 does not work, test login without password (assuming auth key)
test_ssh_login "${NODE}" "${keyfile}" || {
    echo "ERROR: login test using ssh failed. Abort."
    exit 1
}

# default REMOTE_CMD is bash
[ -z "${REMOTE_CMD}" ] && { REMOTE_CMD="bash"; }
# run remote shell with REMOTE_CMD
remote_bash_shell "${NODE}" "${keyfile}" "${REMOTE_CMD}"
cleanup
