#!/bin/bash
set -e

#
# Installs reboot script
# It consists of
# * reboot scripts
# * cronjob
# * run reboot script
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
LOG_FILE="${LOG_DIR}/reboot.log"
REBOOT_SCRIPT="${SCRIPT_DIR}/reboot.sh"

# logrotate
LOGROTATE_CONF="${SCRIPT_DIR}/logrotate.conf"
LOGROTATE_STATE="${LOG_DIR}/logrotate_reboot.state"
LOGROTATE_LOG="${LOG_DIR}/logrotate_reboot.log"

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

#####################################################
# Main program
#####################################################

check_user || {
    echo "User mismatch. Script must run as user: ${USER}"
    exit 1
}

# remove reboot from crontab
crontab -l | grep -v 'reboot' | crontab - || { echo "Ignore error: $?"; }

[ -f "${REBOOT_SCRIPT}" ] || {
    echo "File does not exist: ${REBOOT_SCRIPT}"
    exit 2
}
chmod 700 "${REBOOT_SCRIPT}"

# .. and install cronjob - run after each reboot (sleep 5min)
(
    crontab -l
    echo "@reboot sleep 300 && ${REBOOT_SCRIPT} >> ${LOG_FILE} 2>&1"
) | sort | uniq | crontab - || {
    echo "Error adding cronjob. Code: $?"
    exit 2
}

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
        echo "30 2 * * * /usr/sbin/logrotate -s ${LOGROTATE_STATE} -l ${LOGROTATE_LOG} ${LOGROTATE_CONF} >/dev/null 2>&1"
    ) | sort | uniq | crontab - || {
        echo "Error adding cronjob. Code: $?"
        exit 2
    }
else
    echo "File does not exist: ${LOGROTATE_CONF}"
    echo "Could not install logrotate cronjob"
    exit 2
fi

# finally, run reboot script
${REBOOT_SCRIPT} 

exit 0
