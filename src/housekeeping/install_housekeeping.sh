#!/bin/bash
set -e

#
# Installs the free space management for all nodes
#
# Author: cdeck3r
#

# Params: none

# Exit codes
# 1 - if precond not satisfied
# 2 - if install routing breaks

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
# logrotate
LOG_DIR="${USER_HOME}/log"
CONF_FILE="${SCRIPT_DIR}/logrotate.conf"
STATE_FILE="${LOG_DIR}/logrotate_housekeeping.state"
LOGROTATE_LOG_FILE="${LOG_DIR}/logrotate_housekeeping.log"

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

#####################################################
# Main program
#####################################################

check_user || {
    log_echo "ERROR" "User mismatch. Script must run as user: ${USER}. Abort."
    exit 1
}
