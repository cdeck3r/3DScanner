#!/bin/bash

set -e -u

#
# Enables the webserver for serving the index.html
# containing the IP of the 3DScanner raspi
# See: https://github.com/cdeck3r/3DScanner/docs/dyndns.md
#
# Params: none

# Exit codes
# 1 - if precond not satisfied
# 2 - if other things break

# this directory is the script directory
SCRIPT_DIR="$(
    cd "$(dirname "$0")" || exit
    pwd -P
)"
cd "$SCRIPT_DIR" || exit
# shellcheck disable=SC2034
SCRIPT_NAME=$0

# variables
PORT=80
SRC_IP="134.103.0.0/16" # scanner network

# Logging
LOG_DIR="${SCRIPT_DIR}/log"
LOG_FILE="${LOG_DIR}/dyndns.log"
NWEB_LOG="${SCRIPT_DIR}/nweb.log"

# logrotate
LOGROTATE_CONF="${SCRIPT_DIR}/logrotate.conf"
LOGROTATE_STATE="${LOG_DIR}/logrotate_dyndns.state"
LOGROTATE_LOG="${LOG_DIR}/logrotate_dyndns.log"

#####################################################
# Include Helper functions
#####################################################

# shellcheck disable=SC1090
source "${SCRIPT_DIR}/funcs.sh"
assert_on_pc

# check dyndns script
[[ -x "${SCRIPT_DIR}/dyndns.sh" ]] || {
    log_echo "ERROR" "Dyndns script not executable: ${SCRIPT_DIR}/dyndns.sh"
    exit 1
}
# check webserver
[[ -f "${SCRIPT_DIR}/nweb" ]] || {
    log_echo "ERROR" "Webserver does not exist: nweb"
    exit 1
}
[[ -x "${SCRIPT_DIR}/nweb" ]] || {
    log_echo "ERROR" "Webserver nweb is not executable"
    exit 1
}
# check log stuff
[[ -f "${LOGROTATE_CONF}" ]] || {
    log_echo "ERROR" "Required file not found: ${LOGROTATE_CONF}"
    exit 1
}
# create log directory, if not exist
[[ -d "${LOG_DIR}" ]] || {
    log_echo "WARN" "Log directory does not exist: ${LOG_DIR}"
    log_echo "INFO" "Will create log directory: ${LOG_DIR}"
    mkdir -p "${LOG_DIR}" || {
        log_echo "ERROR" "Could not create log directory: ${LOG_DIR}"
        exit 2
    }
}

#####################################################
# Main program
#####################################################

sudo -s -- <<EOF 
source "${SCRIPT_DIR}/funcs.sh"

# kill exiting process
pkill -f "nweb ${PORT}" || { 
    log_echo "WARN" "Process nweb on port ${PORT} not found"
}

# open firewall
log_echo "INFO" "Open firewall. Allow from ${SRC_IP} to local port ${PORT}"
ufw allow from "${SRC_IP}" to any port "${PORT}" proto tcp comment 'HSRT 3DScanner End-user Access'

# start webserver
log_echo "INFO" "Start webserver nweb on port ${PORT}"
"${SCRIPT_DIR}"/nweb "${PORT}" .

# list nweb processes
# shellcheck disable=SC2009
ps ax | grep nweb

# update cronjob to handle reboot
crontab -l | grep -v 'nweb' | crontab - || { log_echo "ERROR" "Ignore error: $?"; }
(
    crontab -l
    echo "@reboot sleep 300 && ufw allow from ${SRC_IP} to any port ${PORT} proto tcp comment 'HSRT 3DScanner End-user Access' && ${SCRIPT_DIR}/nweb ${PORT} ${SCRIPT_DIR}"
) | sort | uniq | crontab - || {
    log_echo "ERROR" "Error adding cronjob. Code: $?"
    exit 2
}

EOF

# Configure logrotate.conf
# replace olddir, add logfiles
grep -q "^olddir" "${LOGROTATE_CONF}" || {
    log_echo "INFO" "Will add olddir directive in file: ${LOGROTATE_CONF}"
    echo "olddir ${LOG_DIR}"
}
sed "s|^olddir.*|olddir $LOG_DIR|" -i "${LOGROTATE_CONF}"
grep -q "${LOG_FILE}" "${LOGROTATE_CONF}" || {
    log_echo "INFO" "Add logfile to logrotate.conf: ${LOG_FILE}"
    echo "${LOG_FILE} {}" >>"${LOGROTATE_CONF}"
}
grep -q "${NWEB_LOG}" "${LOGROTATE_CONF}" || {
    log_echo "INFO" "Add logfile to logrotate.conf: ${NWEB_LOG}"
    echo "${NWEB_LOG} {}" >>"${LOGROTATE_CONF}"
}

# Install cronjob
log_echo "INFO" "Install cronjob for ${SCRIPT_NAME}"
crontab -l | grep -v 'dyndns' | crontab - || { log_echo "ERROR" "Ignore error: $?"; }
(
    crontab -l
    echo "*/5 * * * * ${SCRIPT_DIR}/dyndns.sh >> ${LOG_FILE}"
    echo "0 2 * * * /usr/sbin/logrotate -v -s ${LOGROTATE_STATE} ${LOGROTATE_CONF} >${LOGROTATE_LOG} 2>&1"
) | sort | uniq | crontab - || {
    log_echo "ERROR" "Error adding cronjob. Code: $?"
    exit 2
}

exit 0
