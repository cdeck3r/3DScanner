#!/bin/bash
set -e

#
# Customizes the RaspiOS image with a systemd boot service
# It installs `booter.sh` and creates the service 
# in th RaspiOS filesystem (on `/mnt` by default).
# 
# Author: cdeck3r
#

# Params: none

# Exit codes
# 1: if pre-requisites are not fulfilled
# 2: fatal error prohibiting further progress, see terminal window

# this directory is the script directory
SCRIPT_DIR="$(
    cd "$(dirname "$0")" || exit
    pwd -P
)"
cd "$SCRIPT_DIR" || exit
# shellcheck disable=SC2034
SCRIPT_NAME=$0

# variables
RASPIOS_MNT="/mnt"

#####################################################
# Include Helper functions
#####################################################

# ...

#####################################################
# Main program
#####################################################

# check 
if [ ! -d "${RASPIOS_MNT}"/home/pi ]; then
    echo "Probably not a RaspiOS image: ${RASPIOS_MNT}"
    exit 1
fi

# save current dir on stack
pushd "${RASPIOS_MNT}" >/dev/null
cd "${RASPIOS_MNT}" || { exit 1; } 

echo "INFO: script not implemented yet"

# return to current dir from stack
popd >/dev/null