#!/bin/bash
set -e

#
# Install scanner software for centralnodes
#
# Author: cdeck3r
#

# Params: none

# variables
USER=pi
USER_HOME="/home/${USER}"
REPO_DIR="/boot/autosetup/3DScanner"
SCANODIS_INSTALL_DIR="${REPO_DIR}/src/scanodis"
SCANODIS_INSTALL_SCRIPT="${SCANODIS_INSTALL_DIR}/install_scanodis.sh"
SCANODIS_USER_DIR="${USER_HOME}/$(basename ${SCANODIS_INSTALL_DIR})"
USER_ID="$(id -u ${USER})"
# variables for homie apparatus device install
HOMIE_NODES_DIR="${REPO_DIR}/src/homie-nodes"
HOMIE_APPARATUS_DIR="${HOMIE_NODES_DIR}/homie-apparatus"
HOMIE_APPARATUS_USER_DIR="${USER_HOME}/$(basename ${HOMIE_APPARATUS_DIR})"
SERVICE_INSTALL_SCRIPT="${HOMIE_NODES_DIR}/install_homie_service.sh"

# Exit codes
# >0 if script breaks

# this directory is the script directory
SCRIPT_DIR="$(
    cd "$(dirname "$0")" || exit
    pwd -P
)"

# ignore wrong date
apt-get update -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false

apt-get install -y \
    arp-scan \
    sshpass \
    avahi-utils \
    nginx \
    python3-pip \
    mosquitto \
    mosquitto-clients

# cleanup
apt-get clean && rm -rf /var/lib/apt/lists/*

# additional python packages
pip3 install --force-reinstall pyyaml

# homie convention https://github.com/mjcumming/homie4
pip3 install --force-reinstall 'Homie4==0.3.4' 'paho-mqtt==1.5.0'

# configure broker
cp "${SCRIPT_DIR}/centralnode_mosquitto.conf" /etc/mosquitto/conf.d
chmod 644 /etc/mosquitto/conf.d/centralnode_mosquitto.conf
chown root:root /etc/mosquitto/conf.d/centralnode_mosquitto.conf

# start up the broker service
systemctl enable mosquitto.service
systemctl start mosquitto.service
systemctl restart mosquitto.service # refresh conf

# install scanodis (scanner node discovery)
chmod 755 "${SCANODIS_INSTALL_SCRIPT}"
rm -rf "${SCANODIS_USER_DIR}" # cleanup
su -c "XDG_RUNTIME_DIR=/run/user/${USER_ID} ${SCANODIS_INSTALL_SCRIPT}" "${USER}"
systemctl restart cron.service

# install homie service; run as ${USER}
# 1. copy homie device software
# 2. enable the service start at boot
# 3. install service
rm -rf "${HOMIE_APPARATUS_USER_DIR}" # cleanup
su -c "cp -r ${HOMIE_APPARATUS_DIR} ${USER_HOME}" "${USER}"
# enable the service start at each Raspi boot-up for the user ${USER}
loginctl enable-linger "${USER}" || { echo "Error ignored: $?"; }
chmod 755 "${SERVICE_INSTALL_SCRIPT}"
su -c "XDG_RUNTIME_DIR=/run/user/${USER_ID} ${SERVICE_INSTALL_SCRIPT}" "${USER}"
