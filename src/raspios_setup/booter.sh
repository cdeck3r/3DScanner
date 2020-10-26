#!/bin/bash
set -e

#
# Script to initialize a node-specific Raspi for the 3DScanner
# It installs the autosetup.zip and enables the SSH service.
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
DONE=/boot/booter.done
AUTOSETUP_CAMNODE_ZIP=/boot/autosetup_camnode.zip
AUTOSETUP_CENTRALNODE_ZIP=/boot/autosetup_centralnode.zip
AUTOSETUP_DIR=/boot/autosetup
AUTOSETUP="${AUTOSETUP_DIR}"/autosetup.sh

#####################################################
# Include Helper functions
#####################################################

set_timezone () {
    # src: https://raspberrypi.stackexchange.com/questions/87164/setting-timezone-non-interactively
    local MY_TZ=$1

    CURR_TZ=$(timedatectl show --property=Timezone --value)
    if [ $CURR_TZ != $MY_TZ ]; then
        timedatectl set-timezone "${MY_TZ}"
    fi
}

set_node_name () {
    # src: https://github.com/nmcclain/raspberian-firstboot/blob/master/examples/simple_hostname/firstboot.sh
    local NEW_NAME=$1

    if [ -e /sys/class/net/eth0 ]; then
        MAC=$(cat /sys/class/net/eth0/address | tr -d ':')
    else
        MAC="000000000000"
    fi
    
    NEW_NAME=${NEW_NAME}-${MAC}
    CURR_HOSTNAME=$(hostname)
    
    if [ "${CURR_HOSTNAME}" != "${NEW_NAME}" ]; then
        echo "${NEW_NAME}" > /etc/hostname
        sed -i "s/${CURR_HOSTNAME}/${NEW_NAME}/g" /etc/hosts
        hostname "${NEW_NAME}"
        # restart avahi
        systemctl restart avahi-daemon.service
    fi
}

enable_ssh () {
    systemctl enable ssh
    systemctl start ssh
}

tool_check () {
    # check for required tools in image's filesystem
    TOOLS=('wget' 'unzip' 'md5sum' 'sed' 'tr')
    for t in "${TOOLS[@]}"
    do
        TOOL=$(find / -name $t)
        if [ -z "$TOOL" ]; then
            echo "Tool not found: $t"
            # make sure ssh runs 
            enable_ssh
            exit 1
        fi
    done
}

#####################################################
# Main program
#####################################################

# check work to do
if [ -f "${DONE}" ]; then
    # nothing to do
    echo "booter.done found. Will do nothing."
    # make sure ssh runs 
    enable_ssh
    exit 0
fi

# we need some tools for the next steps
tool_check

# do some basic config
set_timezone "Europe/Berlin"
set_node_name "node"

# select autosetup.zip
# we will prefer camnode setup over central node, if it exists.
unset AUTOSETUP_ZIP
if [ -f "${AUTOSETUP_CAMNODE_ZIP}" ]; then
    AUTOSETUP_ZIP="${AUTOSETUP_CAMNODE_ZIP}"
elif [ -f "${AUTOSETUP_CENTRALNODE_ZIP}" ]; then
    AUTOSETUP_ZIP="${AUTOSETUP_CENTRALNODE_ZIP}"
fi

# unzip and run autosetup.zip
# src for test expression: https://stackoverflow.com/a/13864829
if [ ! -z "${AUTOSETUP_ZIP+x}" ]; then # var is set
    echo "Install ${AUTOSETUP_ZIP}"
    rm -rf "${AUTOSETUP_DIR}" # delete existing one
    unzip "${AUTOSETUP_ZIP}" -d "${AUTOSETUP_DIR}"
    if [ -f "${AUTOSETUP}" ]; then
        chmod 744 "${AUTOSETUP}" && "${AUTOSETUP}"
    else
        echo "File not found: ${AUTOSETUP}"
    fi
else # var is unset
    #nothing to do    
    echo "autosetup.zip not found. Nothing to do."
fi

# make sure ssh runs 
enable_ssh

exit 0