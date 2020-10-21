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
AUTOSETUP=/boot/autosetup.zip
AUTOSETUP_DIR=/boot/autosetup

#####################################################
# Include Helper functions
#####################################################

set_timezone () {
    # src: https://raspberrypi.stackexchange.com/questions/87164/setting-timezone-non-interactively
    MY_TZ="Europe/Berlin"

    CURR_TZ=$(timedatectl show --property=Timezone --value)
    if [ $CURR_TZ != $MY_TZ ]; then
        timedatectl set-timezone Europe/Berlin
    fi
}

set_node_name () {
    # src: https://github.com/nmcclain/raspberian-firstboot/blob/master/examples/simple_hostname/firstboot.sh
    NEW_NAME="testnode"
    
    if [ $(hostname) != $NEW_NAME ]; then
        echo $NEW_NAME > /etc/hostname
        sed -i "s/raspberrypi/$NEW_NAME/g" /etc/hosts
        hostname $NEW_NAME
        # restart avahi
        systemctl restart avahi-daemon.service
    fi
}

enable_ssh () {
    systemctl enable ssh
    systemctl start ssh
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

# do some basic config
set_timezone
set_node_name 

# unzip autosetup.zip
if [ -f "${AUTOSETUP}" ]; then 

    # check for required tools in image's filesystem
    TOOLS=('wget' 'unzip' 'md5sum' 'sed')
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

    echo "Install ${AUTOSETUP}"
    unzip "${AUTOSETUP}" -d "${AUTOSETUP_DIR}"
    # install ssh keys
    # download scripts from repo
    # start install scripts
else
    #nothing to do    
    echo "autosetup.zip not found. Nothing to do."
fi

# make sure ssh runs 
enable_ssh

exit 0