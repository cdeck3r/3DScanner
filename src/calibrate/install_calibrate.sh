#!/bin/bash
set -e

#
# Installs software for camnode calibration
# It consists of
# * export image scripts
# * logrotate config 
# * cronjob
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
LOG_DIR="${USER_HOME}/log"
LOG_FILE="${LOG_DIR}/calibrate.log"

EXPORT_SCRIPT="${SCRIPT_DIR}/export_image.sh"

# logrotate
LOGROTATE_CONF="${SCRIPT_DIR}/logrotate.conf"
LOGROTATE_STATE="${LOG_DIR}/logrotate_calibrate.state"
LOGROTATE_LOG="${LOG_DIR}/logrotate_calibrate.log"

#####################################################
# Include Helper functions
#####################################################

# verfies the script runs as ${USER}
check_user() {
    local CURR_USER

    CURR_USER=$(id --user --name)
    if [ "${CURR_USER}" != "${USER}" ]; then
        return 1
    fi

    return 0
}

# check for reboot script and make executable
check_script() {
    local script=$1

    [ -f "${script}" ] || {
        echo "File does not exist: ${script}"
        exit 2
    }
    chmod 700 "${script}"
}

#####################################################
# Main program
#####################################################

check_user || {
    echo "User mismatch. Script must run as user: ${USER}"
    exit 1
}

# check and make executable
check_script "${EXPORT_SCRIPT}"

# remove calibrate cronjobs from crontab
# works because scripts in '../calibrate/..' directory
crontab -l | grep -v 'calibrate' | crontab - || { echo "Ignore error: $?"; }


# create log directory
mkdir -p "${LOG_DIR}"

grep "${LOG_FILE}" "${LOGROTATE_CONF}" >/dev/null || {
    echo "Logfile not under logrotate: ${LOG_FILE}"
    echo "Add logfile to config file: ${LOGROTATE_CONF}"
}

# install daily logrotate cronjob - run each night at 2:30am
if [ -f "${LOGROTATE_CONF}" ]; then
    (
        crontab -l
        echo "0 2 * * * /usr/sbin/logrotate -s ${LOGROTATE_STATE} -l ${LOGROTATE_LOG} ${LOGROTATE_CONF} >/dev/null 2>&1"
    ) | sort | uniq | crontab - || {
        echo "Error adding cronjob. Code: $?"
        exit 2
    }
else
    echo "File does not exist: ${LOGROTATE_CONF}"
    echo "Could not install logrotate cronjob"
    exit 2
fi

exit 0
