#!/bin/bash
set -e

#
# Install the nodes as homie devices
#
# Author: cdeck3r
#

# Params: none

# Exit codes
# 1 if pre-cond not fulfilled
# 2 if script breaks

# this directory is the script directory
SCRIPT_DIR="$(
    cd "$(dirname "$0")" || exit
    pwd -P
)"
cd "$SCRIPT_DIR" || exit
# shellcheck disable=SC2034
SCRIPT_NAME=$0

# variables
NODETYPE=$1
USER=pi
USER_HOME="/home/${USER}"
SERVICE_UNIT_DIR="${USER_HOME}/.config/systemd/user"

#####################################################
# Include Helper functions
#####################################################

# print usage message
usage() {
    echo "Usage: ${SCRIPT_NAME} [CAMNODE | CENTRALNODE]"
}

# verfies the script runs as ${USER}
check_user() {
    local CURR_USER

    CURR_USER=$(id --user --name)
    if [ "${CURR_USER}" != "${USER}" ]; then
        return 1
    fi

    return 0
}

# from /boot/autosetup, or from hostname
derive_nodetype() {
    if [ -f "/boot/autosetup/NODETYPE" ]; then
        NODETYPE=$(head -1 "/boot/autosetup/NODETYPE")
    else
        NODETYPE=$(hostname | cut -d'-' -f1)
    fi

    NODETYPE=$(echo "${NODETYPE}" | tr '[:lower:]' '[:upper:]')
    echo "${NODETYPE}"
}

#####################################################
# Main program
#####################################################

check_user || {
    echo "User mismatch. Script must run as user: ${USER}"
    exit 1
}

# if nodetype not empty: leave it as it is
if [ -z "${NODETYPE}" ]; then
    NODETYPE=$(derive_nodetype)
fi

# select service by nodetype
if [ "${NODETYPE}" = "CAMNODE" ]; then
    SERVICE_UNIT_FILE="homie_camnode.service"
elif [ "${NODETYPE}" = "CENTRALNODE" ]; then
    SERVICE_UNIT_FILE="homie_centralnode.service"
else
    echo "No valid nodetype: ${NODETYPE}"
    usage
    exit 2
fi

# install SERVICE_UNIT_FILE
mkdir -p "${SERVICE_UNIT_DIR}"
# test
FOUND_SERVICE=$(systemctl --user --no-pager --no-legend list-unit-files | grep -c "${SERVICE_UNIT_FILE}")
echo "Found instances of ${SERVICE_UNIT_FILE} running: ${FOUND_SERVICE}"
# stop / remove
systemctl --user --no-pager --no-legend stop "${SERVICE_UNIT_FILE}" || { echo "Error ignored: $?"; }
systemctl --user --no-pager --no-legend disable "${SERVICE_UNIT_FILE}" || { echo "Error ignored: $?"; }
# (re)place the new service
cp "${SCRIPT_DIR}/${SERVICE_UNIT_FILE}" "${SERVICE_UNIT_DIR}"
systemctl --user daemon-reload || { echo "Error ignored: $?"; }
systemctl --user --no-pager --no-legend start "${SERVICE_UNIT_FILE}" || { echo "Error ignored: $?"; }
systemctl --user --no-pager --no-legend enable "${SERVICE_UNIT_FILE}" || { echo "Error ignored: $?"; }
# we expect the service acti
STATE=$(systemctl --user --no-pager --no-legend is-active "${SERVICE_UNIT_FILE}")

if [ "${STATE}" != "active" ]; then
    echo "Service not active: ${SERVICE_UNIT_FILE}"
    exit 2
fi

exit 0
