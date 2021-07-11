#!/bin/bash

#
# Remotely runs a shell command on a list of camnodes
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
REMOTE_SHELL="${SCRIPT_DIR}/remote_bash.sh"
REMOTE_CMD="hostname && journalctl --no-pager | grep voltage | tail -1"
# arpscan.txt
IP_LIST=$1

#####################################################
# Include Helper functions
#####################################################

#####################################################
# Main program
#####################################################
[ -e "${REMOTE_SHELL}" ] || {
    echo "Could not find remote shell: ${REMOTE_SHELL}"
    exit 1
}

[ -f "${IP_LIST}" ] || {
    echo "Could not find IP list: ${IP_LIST}"
    exit 1
}

cat "${IP_LIST}" | xargs -n 1 -I addr "${REMOTE_SHELL}" addr "CAMNODE" "${REMOTE_CMD}"
