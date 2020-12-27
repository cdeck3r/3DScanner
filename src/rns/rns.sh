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
PI_USER=pi
FILE_DIR=$1
NODE_ADDR=$2
USE_SSHPASS=1
# Array for setup files to deploy
declare -a SETUP_FILES

#####################################################
# Include Helper functions
#####################################################

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
    local ssh_login

    ssh_login=$(ssh_cmd)
    ssh_reboot="${ssh_login} -t ${PI_USER}@${node} sudo shutdown -r now"
    ${ssh_reboot}
}

rm_booter_done() {
    local node=$1
    local ssh_login

    ssh_login=$(ssh_cmd)
    ssh_rm_booter_done="${ssh_login} -t ${PI_USER}@${node} sudo rm -rf /boot/booter.done"
    ${ssh_rm_booter_done}
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
    ${ssh_hostname} && {
        echo "Login successful. USE_SSHPASS: ${USE_SSHPASS}"
        return 0
    }

    # test with USE_SSHPASS=0
    USE_SSHPASS=0
    ssh_login=$(ssh_cmd)
    ssh_hostname="${ssh_login} -t ${PI_USER}@${node} hostname"
    ${ssh_hostname} || {
        echo "Login does not work. USE_SSHPASS: ${USE_SSHPASS}"
        return 1
    }
}

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
[ -d "${FILE_DIR}" ] || {
    echo "File directory does not exist: ${FILE_DIR}"
    exit 1
}
[ -z "${NODE_ADDR}" ] && {
    echo "No node address provided. Abort."
    exit 1
}
echo "#########################"
echo "#      Ping test        #"
echo "#########################"
ping -c 3 "${NODE_ADDR}" || {
    echo "Cannot ping node: ${NODE_ADDR}"
    exit 1
}
echo "#########################"
echo ""

# test login
# 1. providing password using sshpass
# 2. if 1 does not work, test login without password (assuming auth key)
test_ssh_login "${NODE_ADDR}" || {
    echo "ERROR: login test using ssh failed. Abort."
    exit 1
}
echo "SUCCESS: ssh login test successful with USE_SSHPASS = ${USE_SSHPASS}"

# we walk through the $FILE_DIR for files
echo "Compile file list..."
compile_files "${FILE_DIR}"
echo "File list: ${SETUP_FILES[*]}"

# copy files
for f in "${SETUP_FILES[@]}"; do
    echo "Copy file ${f} to node ${NODE_ADDR}"
    copy_file "${f}" "${NODE_ADDR}" "/boot" || {
        echo "Error copying file: ${f}"
        exit 2
    }
done

# restart the autosetup process
echo "Reboot and restart the autosetup process..."
rm_booter_done "${NODE_ADDR}"
shutdown_reboot "${NODE_ADDR}"
