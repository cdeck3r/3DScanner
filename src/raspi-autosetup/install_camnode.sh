#!/bin/bash
set -e

#
# Install scanner software for cam(era)nodes
#
# Author: cdeck3r
#

# Params: none

# Exit codes
# >0 if script breaks

# variables
USER=pi
USER_HOME="/home/${USER}"
IMG_DIR="${USER_HOME}/images"
REPO_DIR="/boot/autosetup/3DScanner"

# ignore wrong date
apt-get update -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false

apt-get install -y \
    python3-pip \
    mosquitto-clients

# cleanup
apt-get clean && rm -rf /var/lib/apt/lists/*

# homie convention https://github.com/mjcumming/homie4
pip3 install --force-reinstall 'Homie4==0.3.4' 'paho-mqtt==1.5.0'

# python camera package
pip3 install --force-reinstall picamera


# install homie service; run as ${USER}
# 1. copy homie device software
# 2. mkdir IMG_DIR
# 3. install service
su -c "cp -r ${REPO_DIR}/src/homie-nodes/homie-camnode ${USER_HOME}" "${USER}"
su -c "mkdir -p ${IMG_DIR}" "${USER}"
su -c 'XDG_RUNTIME_DIR=/run/user/$(id -u) /boot/autosetup/3DScanner/src/homie-nodes/install_node_services.sh' "${USER}"
