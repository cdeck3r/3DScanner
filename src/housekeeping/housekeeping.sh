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

usage() {
    echo "Usage: ${SCRIPT_NAME} <directory> <low watermark> [high watermark]"
}

# Helps to mock-up the logfile
# when script is under test
get_logfile() {
    mkdir -p "${LOG_DIR}" # redundantly executed, but needed this way for mocking
    echo "${LOG_FILE}"
}

# like log_echo, but with a fixed file as destination
log_echo_file() {
    local _LOG_LEVEL=$1
    local _LOG_MSG=$2
    local _LOG_FILE

    _LOG_FILE=$(get_logfile)
    log_echo "${_LOG_LEVEL}" "${_LOG_MSG}" >>"${_LOG_FILE}"
}

check_param() {
    # first parameter must not be empty
    [[ -z "${DATA_DIR}" ]] && {
        log_echo "ERROR" "Data directory parameter not set."
        return 1
    }

    # watermark params must not be empty and must be integers
    [[ -z "${LOW_MARK}" ]] && {
        log_echo "ERROR" "Low watermark parameter not set."
        return 1
    }
    [[ "${LOW_MARK}" =~ ^[0-9]+$ ]] || {
        log_echo "ERROR" "Low watermark is not an integer."
        return 1
    }

    # high watermark is allowed to be empty
    [[ -z "${HIGH_MARK}" ]] || {
        [[ "${HIGH_MARK}" =~ ^[0-9]+$ ]] || {
            log_echo "ERROR" "High watermark is not an integer."
            return 1
        }
    }

    return 0

}

#####################################################
# Main program
#####################################################

# first things first
check_user || {
    log_echo "ERROR" "User mismatch. Script must run as user: ${USER}. Abort."
    exit 1
}
check_param || {
    usage
    exit 1
}

# param validity check
[ -d "${DATA_DIR}" ] || {
    log_echo "ERROR" "Directory does not exists: ${DATA_DIR}. Abort."
    exit 2
}
# watermark params must be in certain ranges
TOTAL=$(df --output=size -k "${PARTITION}" | tail -n 1 | xargs)
((LOW_MARK > TOTAL)) && {
    log_echo "ERROR" "Low watermark is greater than total disk space. Abort."
    exit 2
}

# let's work
log_echo_file "INFO" "Start housekeeping for directory (low/high): ${DATA_DIR} (${LOW_MARK} / ${HIGH_MARK})"

# high watermark is allowed to be empty, but then it is set to TOTAL
[[ -z "${HIGH_MARK}" ]] && {
    HIGH_MARK="${TOTAL}"
    log_echo_file "INFO" "High watermark not specified. Will delete the entire directory."
}
((HIGH_MARK > TOTAL)) && { log_echo_file "WARN" "High watermark is greater than total disk space."; }

FREE=$(df --output=avail -k "${PARTITION}" | tail -n1 | xargs)

((FREE > LOW_MARK)) && {
    log_echo_file "INFO" "Sufficient free space avail: ${FREE}"
    exit 0
}

((FREE < LOW_MARK)) && {
    files_deleted=0
    # start deleting files from DATA_DIR
    log_echo_file "WARN" "Insufficient space: ${FREE}"
    log_echo_file "INFO" "Start deleting files from directory: ${DATA_DIR}"
    mapfile -t DATA_FILE_ARRAY < <(find "${DATA_DIR}" -type f -printf "%T+ %p\\n" | sort | cut -d' ' -f2)

    for f in "${DATA_FILE_ARRAY[@]}"; do
        rm -rf "$f"
        ((files_deleted += 1))
        FREE=$(df --output=avail -k "${PARTITION}" | tail -n1 | xargs)
        ((FREE > HIGH_MARK)) && { break; }
    done
}

# Finalize: delete all empty dirs in DATA_DIR
log_echo_file "INFO" "Delete all empty directories in directory: ${DATA_DIR}"
find "${DATA_DIR}" -type d -empty -delete >/dev/null

log_echo_file "INFO" "Deleted files: ${files_deleted}"
