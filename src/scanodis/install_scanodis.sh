#!/bin/bash
set -e

#
# Installs scanodis (scanner node discovery)
# It consists of
# * scanodis scripts
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
SCANODIS_INSTALL_DIR="${USER_HOME}/scanodis"
SCANODIS_SCRIPT="${SCANODIS_INSTALL_DIR}/scanodis.sh"
LOG_DIR="${USER_HOME}/log"
LOG_FILE="${LOG_DIR}/scanodis.log" # we assume the same logfile on logrotate.conf
LOG_CONF="${SCRIPT_DIR}/logrotate.conf"

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

# remove scanodis from crontab
crontab -l | grep -v 'scanodis' | crontab - || { echo "Ignore error: $?"; }

# copy files, test ...
mkdir -p "${LOG_DIR}"
mkdir -p "${SCANODIS_INSTALL_DIR}"
cp -R "${SCRIPT_DIR}/"* "${SCANODIS_INSTALL_DIR}"
[ -f "${SCANODIS_SCRIPT}" ] || {
    echo "File does not exist: ${SCANODIS_SCRIPT}"
    exit 2
}
chmod 700 "${SCANODIS_SCRIPT}"

grep "${LOG_FILE}" "${LOG_CONF}" > /dev/null || {
    echo "Logfile not under logrotate: ${LOG_FILE}"
    echo "Add logfile to config file: ${LOG_CONF}"
}

# .. and install cronjob - run each hour at minute 0
(
    crontab -l
    echo "0 * * * * ${SCANODIS_SCRIPT} > ${LOG_FILE} 2>&1"
) | crontab - || {
    echo "Error adding cronjob. Code: $?"
    exit 2
}

# at the end, we initially start the trackers
"${SCANODIS_SCRIPT}" > "${LOG_FILE}" 2>&1 || { echo "Ignore error: $?"; }

exit 0
