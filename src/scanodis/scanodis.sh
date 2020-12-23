#!/bin/bash
set -e

#
# scanodis (scanner node discovery)
# It consists of tracker script
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
TRACKER_INI="/boot/autosetup/scanodis_tracker.ini"
# logrotate
LOG_DIR="${USER_HOME}/log"
CONF_FILE="${SCRIPT_DIR}/logrotate.conf"
STATE_FILE="${LOG_DIR}/logrotate.state"
LOGROTATE_LOG_FILE="${LOG_DIR}/logrotate.log"

#####################################################
# Include Helper functions
#####################################################

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

# take care of my logfiles
scanodis_logroate() {
    [ -f "${CONF_FILE}" ] || {
        echo "Config file not found: ${CONF_FILE}. Logs will not rotate."
        return 0
    }
    /usr/sbin/logrotate -s "${STATE_FILE}" -l "${LOGROTATE_LOG_FILE}" "${CONF_FILE}"
}

# tracker may use this functions
# to retrieve the tracker value from the ini file
# given the tracker name
#
# Param: tracker variable name as string
# Return: tracker variable value as string
get_tracker() {
    local tracker_varname
    tracker_varname=$1

    # Return: tracker variable value
    echo "${!tracker_varname}"
}

#####################################################
# Main program
#####################################################

check_user || {
    log_echo "ERROR" "User mismatch. Script must run as user: ${USER}. Abort."
    exit 1
}

# just be sure
mkdir -p "${LOG_DIR}"

# load tracker list
[ -f "${TRACKER_INI}" ] || {
    log_echo "ERROR" "No tracker found. File does not exist: ${TRACKER_INI}. Abort."
    exit 1
}
# shellcheck disable=SC1090
# shellcheck disable=SC1091
source "${TRACKER_INI}"

# find and run trackers
# source: https://github.com/koalaman/shellcheck/wiki/SC2044#correct-code
while IFS= read -r -d '' tracker; do
    # shellcheck disable=SC1090
    # shellcheck disable=SC1091
    source "${tracker}"
    log_echo "INFO" "Run tracker: ${tracker}"
    publish_to_tracker
done < <(find "${SCRIPT_DIR}" -type f -name '*_tracker_*.sh' -print0 | sort -z)

# take care of my logs
log_echo "INFO" "Start scanodis logrotate"
scanodis_logroate
