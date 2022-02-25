#!/bin/bash
set -e

#
# rns - remote node setup
#
# Author: cdeck3r
#

# Params:
# $1 - directory containing files
# $2 - node address

# Exit codes
# 1 - if precond not satisfied
# 2 - if process breaks

# this directory is the script directory
SCRIPT_DIR="$(
    cd "$(dirname "$0")" || exit
    pwd -P
)"
cd "$SCRIPT_DIR" || exit
# shellcheck disable=SC2034
SCRIPT_NAME=$0

# variables
## cmd line args
NODE_ADDR=$1
DELAY=$2
FILE_DIR=$3
## others
PI_USER=pi
USE_SSHPASS=1
PING_ENABLED=1 #default
# Array for setup files to deploy
declare -a SETUP_FILES

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
    echo "Usage: ${SCRIPT_NAME} <node address> <delay> [file directory]"
    echo ""
    echo "Arguments:"
    echo "node address - IPv4 address"
    echo "delay        - autosetup delay in minutes"
    echo "file dir     - directory with autosetup files for upload to node"
    echo ""
    echo "Note: Always set SSHPASS variable for user/password login"
    #echo ""
    echo "Default: Will ping the node. Set env variable PINGNODE=0 to disable ping test."
}

can_ping() {
    local node=$1

    [[ PING_ENABLED -eq 1 ]] && {
        echo ""
        echo "########### ping ${node} ###########"
        ping -c 3 "${node}" || {
            return 1
        }
        echo "#################################################"
        echo ""
    }

    return 0
}

ssh_cmd() {
    local SSH_PASS

    if [ "${USE_SSHPASS}" -eq 1 ]; then
        SSH_PASS="sshpass -e"
    else
        SSH_PASS=""
    fi
    SSH_CMD="${SSH_PASS} ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -q"
    echo "${SSH_CMD}"
}

scp_cmd() {
    ssh_login=$(ssh_cmd)
    # replace ssh by scp
    echo "${ssh_login/ssh -o/scp -o}"
}

shutdown_reboot() {
    local node=$1
    local delay=$2
    local ssh_login

    ssh_login=$(ssh_cmd)
    ssh_reboot="${ssh_login} -t ${PI_USER}@${node} sudo shutdown -r ${delay}"
    ${ssh_reboot}
}

rm_booter_done() {
    local node=$1
    local ssh_login

    ssh_login=$(ssh_cmd)
    ssh_rm_booter_done="${ssh_login} -t ${PI_USER}@${node} sudo rm -rf /boot/booter.done"
    ${ssh_rm_booter_done}
}

set_powersave() {
    local node=$1
    local ssh_login

    ssh_login=$(ssh_cmd)
    ssh_set_powersave="${ssh_login} -t ${PI_USER}@${node} echo powersave | sudo tee /sys/devices/system/cpu/cpufreq/policy0/scaling_governor >/dev/null"
    ${ssh_set_powersave}
}

disable_homie_camnode() {
    local node=$1
    local ssh_login
    local remote_user_id
    local disable_cmd

    remote_user_id="id -u ${PI_USER}"
    disable_cmd="export XDG_RUNTIME_DIR=/run/user/$(${remote_user_id}) && systemctl --user stop homie_camnode.service && systemctl --user disable homie_camnode.service"

    ssh_login=$(ssh_cmd)
    ssh_disable_homie_camnode="${ssh_login} -t ${PI_USER}@${node} ${disable_cmd}"
    ${ssh_disable_homie_camnode}
}

switch_off_LED() {
    local node=$1
    local ssh_login
    local switch_off_cmd

    switch_off_cmd="/boot/autosetup/3DScanner/src/blink/blink.sh none"

    ssh_login=$(ssh_cmd)
    ssh_switch_off_LED="${ssh_login} -t ${PI_USER}@${node} ${switch_off_cmd}"
    ${ssh_switch_off_LED}
}

copy_file() {
    local file=$1
    local node=$2
    local dest_dir=$3
    local base_filename

    base_filename=$(basename "${file}")

    # 1. scp to /tmp/file
    # 2. cp /tmp/file to /boot
    # 3. rm /tmp/file
    scp_login=$(scp_cmd)
    scp_copy_file="${scp_login} ${file} ${PI_USER}@${node}:/tmp"
    ${scp_copy_file}

    ssh_login=$(ssh_cmd)
    ssh_cp_dest_dir="${ssh_login} -t ${PI_USER}@${node} sudo cp /tmp/${base_filename} ${dest_dir}"
    ${ssh_cp_dest_dir}

    ssh_rm_tmp="${ssh_login} -t ${PI_USER}@${node} sudo rm -rf /tmp/${base_filename}"
    ${ssh_rm_tmp}
}

test_ssh_login() {
    local node=$1
    local ssh_login

    # assume USE_SSHPASS=1
    ssh_login=$(ssh_cmd)
    ssh_hostname="${ssh_login} -t ${PI_USER}@${node} hostname"
    ${ssh_hostname} >/dev/null && return 0

    # test with USE_SSHPASS=0
    USE_SSHPASS=0
    ssh_login=$(ssh_cmd)
    ssh_hostname="${ssh_login} -t ${PI_USER}@${node} hostname"
    ${ssh_hostname} >/dev/null || return 1
}

#
# takes the FILE_DIR as first arg
# changes the *global* variable SETUP_FILES
#
# See this discussion regarding the use of globals
# https://stackoverflow.com/questions/10582763/how-to-return-an-array-in-bash-without-using-globals
#
compile_files() {
    local FILE_DIR=$1
    SETUP_FILES=()

    # add autosetup.zip file
    # prefers autosetup_camnode.zip, if exists
    if [ -f "${FILE_DIR}/autosetup_camnode.zip" ]; then
        SETUP_FILES=("${SETUP_FILES[@]}" "${FILE_DIR}/autosetup_camnode.zip")
    elif [ -f "${FILE_DIR}/autosetup_centralnode.zip" ]; then
        SETUP_FILES=("${SETUP_FILES[@]}" "${FILE_DIR}/autosetup_centralnode.zip")
    fi

    # add booter.sh
    if [ -f "${FILE_DIR}/booter.sh" ]; then
        SETUP_FILES=("${SETUP_FILES[@]}" "${FILE_DIR}/booter.sh")
    fi
}

#####################################################
# Main program
#####################################################

# some checks first
# shellcheck disable=SC2153
[ -z "${SSHPASS}" ] && {
    echo "Env var SSHPASS not set. Please set variable."
    exit 1
}
# check tools
TOOLS=('ping' 'sshpass' 'scp' 'ssh')
for t in "${TOOLS[@]}"; do
    command -v "${t}" >/dev/null || {
        echo "Could not find tool: $t"
        exit 1
    }
done
[ -z "${NODE_ADDR}" ] && {
    echo "No node address provided. Abort."
    usage
    exit 1
}
[ -z "${DELAY}" ] && {
    echo "No delay specified. Abort."
    usage
    exit 1
}
if ! [ -z "${FILE_DIR}" ]; then
    [ -d "${FILE_DIR}" ] || {
        log_echo "ERROR" "File directory does not exist: ${FILE_DIR}"
        exit 1
    }
    log_echo "INFO" "Update autosetup files for node ${NODE_ADDR} from directory: ${FILE_DIR}"
else
    log_echo "WARN" "No update for autosetup files. Re-run autosetup for node: ${NODE_ADDR}"
fi

! [[ -z "${PINGNODE}" ]] && PING_ENABLED="${PINGNODE}"
can_ping "${NODE_ADDR}" || {
    log_echo "ERROR" "Cannot ping node: ${NODE_ADDR}"
    exit 1
}

# test login
# 1. providing password using sshpass
# 2. if 1 does not work, test login without password (assuming auth key)
test_ssh_login "${NODE_ADDR}" || {
    log_echo "ERROR" "ssh login test failed with USE_SSHPASS=${USE_SSHPASS} for node: ${NODE_ADDR}"
    exit 1
}
log_echo "INFO" "ssh login test successful with USE_SSHPASS=${USE_SSHPASS} for node: ${NODE_ADDR}"

## TODO: encapsulate in a separate function
if ! [[ -z "${FILE_DIR}" ]]; then
    # we walk through the $FILE_DIR for files
    log_echo "INFO" "Compile autosetup file list from ${FILE_DIR}"
    compile_files "${FILE_DIR}"
    log_echo "INFO" "File list: ${SETUP_FILES[*]}"

    # copy files
    for f in "${SETUP_FILES[@]}"; do
        log_echo "INFO" "Copy file ${f} to node ${NODE_ADDR}"
        copy_file "${f}" "${NODE_ADDR}" "/boot" || {
            log_echo "ERROR" "Error copying file to node ${NODE_ADDR}: ${f}"
            exit 2
        }
    done
fi

# restart the autosetup process
log_echo "INFO" "Re-run the autosetup process for node ${NODE_ADDR} in ${DELAY} minutes"
{ disable_homie_camnode "${NODE_ADDR}" && switch_off_LED "${NODE_ADDR}" && set_powersave "${NODE_ADDR}" && rm_booter_done "${NODE_ADDR}" && shutdown_reboot "${NODE_ADDR}" "${DELAY}"; } || {
    log_echo "ERROR" "Could start the autosetup process for node ${NODE_ADDR}"
    exit 2
}

exit 0
