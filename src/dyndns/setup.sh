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
SRC_IP="134.103.0.0/16"

#####################################################
# Include Helper functions
#####################################################

# shellcheck disable=SC1090
source "${SCRIPT_DIR}/funcs.sh"
assert_on_pc

# check webserver
[[ -f "${SCRIPT_DIR}/nweb" ]] || { log_echo "ERROR" "Webserver does not exist: nweb"; exit 1; }
[[ -x "${SCRIPT_DIR}/nweb" ]] || { log_echo "ERROR" "Webserver nweb is not executable"; exit 1; }

#####################################################
# Main program
#####################################################

# kill exiting process
sudo pkill -f "nweb ${PORT}" || { log_echo "WARN" "Process nweb on port ${PORT} not found"; }
# open firewall
log_echo "INFO" "Open firewall. Allow from ${SRC_IP} to local port ${PORT}"
sudo ufw allow from "${SRC_IP}" to any port "${PORT}" proto tcp comment 'HSRT 3DScanner End-user Access'
# start webserver
log_echo "INFO" "Start webserver nweb on port ${PORT}"
sudo ./nweb "${PORT}" .
# list nweb processes
ps ax | grep nweb

# Install cronjob
log_echo "INFO" "Install cronjob for ${SCRIPT_NAME}"
crontab -l | grep -v 'dyndns.sh' | crontab - || { log_echo "ERROR" "Ignore error: $?"; }
(
    crontab -l
    echo "*/5 * * * * ${SCRIPT_DIR}/dyndns.sh >> ${SCRIPT_DIR}/dyndns.log"
) | sort | uniq | crontab - || {
    log_echo "ERROR" "Error adding cronjob. Code: $?"
    exit 2
}

exit 0
