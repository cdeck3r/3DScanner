#!/bin/bash
set -e

#
# Free space management on all nodes
#
# The housekeeping process works as follows:
#
# 1. Check for free space. 
#    Parameter low watermark defines the permitted lower bound.
# 2. In case, we are below the low watermark, 
#    we start deleting the oldest files from a given directory
#    until we are above the high watermark parameter.
#
# Author: cdeck3r
#

# Params: 
# directory, where to delete files from
# low watermark [unit: KB]
# high watermark [unit: KB]
DATA_DIR=$1
LOW_MARK=$2 
HIGH_MARK=$3

# Exit codes
# 1 - if precond not satisfied


# this directory is the script directory
SCRIPT_DIR="$(
    cd "$(dirname "$0")" || exit
    pwd -P
)"
cd "$SCRIPT_DIR" || exit
# shellcheck disable=SC2034
SCRIPT_NAME=$0

# variables
USER=pi
USER_HOME="/home/${USER}"
LOG_DIR="${USER_HOME}/log"
LOG_FILE="${USER_HOME}/log/housekeeping.log"
PARTITION="/" # parti

#####################################################
# Include Helper functions
#####################################################

# shellcheck disable=SC1090
source "${SCRIPT_DIR}/funcs.sh"

# verfies the script runs as ${USER}
check_user() {
    local CURR_USER

    CURR_USER=$(id --user --name)
    if [ "${CURR_USER}" != "${USER}" ]; then
        return 1
    fi

    return 0
}

# like log_echo, but with a fixed file as destination
log_echo_file() {
    local _LOG_LEVEL=$1
    local _LOG_MSG=$2
    
    log_echo "${_LOG_LEVEL}" "${_LOG_MSG}" >> "${LOG_FILE}"
}

#####################################################
# Main program
#####################################################

# first things first
check_user || {
    log_echo "ERROR" "User mismatch. Script must run as user: ${USER}. Abort."
    exit 1
}
[ -d "${DATA_DIR}" ] || {
    log_echo "ERROR" "Directory does not exists: ${DATA_DIR}. Abort."
    exit 1
}
# watermark params must be integers
[[ "${LOW_MARK}" =~ ^[0-9]+$ ]] || { log_echo "ERROR" "Low watermark is not an integer."; exit 1; }
[[ "${HIGH_MARK}" =~ ^[0-9]+$ ]] || { log_echo "ERROR" "High watermark is not an integer."; exit 1; }
# watermark params must be in certain ranges
TOTAL=$(df --output=size -k "${PARTITION}" | tail -n 1 | xargs)
((LOW_MARK > TOTAL)) && { log_echo "ERROR" "Low watermark is greater than total disk space. Abort."; exit 2; }
((HIGH_MARK > TOTAL)) && { log_echo "WARN" "High watermark is greater than total disk space."; }

# just be sure
mkdir -p "${LOG_DIR}"

# let's work
log_echo_file "INFO" "Start housekeeping for directory (low/high): ${DATA_DIR} (${LOW_MARK} / ${HIGH_MARK}"

FREE=$(df --output=avail -k "${PARTITION}" | tail -n1 | xargs)

((FREE > LOW_MARK)) && { log_echo_file "INFO" "Sufficient free space avail: ${FREE}"; exit 0; }

((FREE < LOW_MARK)) && {
    files_deleted=0
    # start deleting files from DATA_DIR
    log_echo_file "WARN" "Insufficient space: ${FREE}"
    log_echo_file "INFO" "Start deleting files from directory: ${DATA_DIR}"
}

log_echo_file "INFO" "Deleted files: ${files_deleted}"
