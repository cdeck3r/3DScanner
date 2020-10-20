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

# check required dirs in image's filesystem
DIRS=('/home/pi' '/lib/systemd/system' '/etc/systemd/system/multi-user.target.wants')
for d in "${DIRS[@]}"
do
    if [ ! -d "${RASPIOS_MNT}"$d ]; then
        echo "Could not find directory in image: $d"
        echo "Probably not a suitable RaspiOS image: ${RASPIOS_MNT}"
        exit 1
    fi
done

# check for required tools in image's filesystem
TOOLS=('wget' 'unzip' 'md5sum')
for t in "${TOOLS[@]}"
do
    TOOL=$(find "${RASPIOS_MNT}" -name $t)
    if [ -z "$TOOL" ]; then
        echo "Tool not found in image: $t"
        exit 2
    fi
done

# check my own ressources
if [ ! -f "${SCRIPT_DIR}"/booter.service ]; then
    echo "booter.service not found"
    exit 2
fi    

# install booter.service and script
echo "INFO: script not implemented yet"
exit 0

cp "${SCRIPT_DIR}"/booter.service "${RASPIOS_MNT}"/lib/systemd/system/ || { echo "Error copying booter.service"; exit 2; }
ln -s "${RASPIOS_MNT}"/lib/systemd/system/booter.service "${RASPIOS_MNT}"/etc/systemd/system/multi-user.target.wants/booter.service || { echo "Error installing booter.service"; exit 2; }

