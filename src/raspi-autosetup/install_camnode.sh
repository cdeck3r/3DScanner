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
HOMIE_NODES_DIR="${REPO_DIR}/src/homie-nodes"
HOMIE_CAMNODE_DIR="${HOMIE_NODES_DIR}/homie-camnode"
HOMIE_CAMNODE_USER_DIR="${USER_HOME}/$(basename ${HOMIE_CAMNODE_DIR})"
SERVICE_INSTALL_SCRIPT="${HOMIE_NODES_DIR}/install_homie_service.sh"
USER_ID="$(id -u ${USER})"

# ignore wrong date
apt-get update -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false

apt-get install -y \
    python3-pip \
    mosquitto-clients

# cleanup
apt-get clean && rm -rf /var/lib/apt/lists/*

# additional python packages
pip3 install --force-reinstall yaml

# homie convention https://github.com/mjcumming/homie4
pip3 install --force-reinstall 'Homie4==0.3.4' 'paho-mqtt==1.5.0'

# python camera package
pip3 install --force-reinstall picamera

# install homie service; run as ${USER}
# 1. copy homie device software
# 2. mkdir IMG_DIR
# 3. enable the service start at boot
# 4. install service
rm -rf "${HOMIE_CAMNODE_USER_DIR}" # cleanup
su -c "cp -r ${HOMIE_CAMNODE_DIR} ${USER_HOME}" "${USER}"
su -c "mkdir -p ${IMG_DIR}" "${USER}"

# enable the service start at each Raspi boot-up for the user ${USER}
loginctl enable-linger "${USER}" || { echo "Error ignored: $?"; }
chmod 755 "${SERVICE_INSTALL_SCRIPT}"
su -c "XDG_RUNTIME_DIR=/run/user/${USER_ID} ${SERVICE_INSTALL_SCRIPT}" "${USER}"
