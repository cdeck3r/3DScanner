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
    avahi-utils \
    nginx \
    python3-pip \
    mosquitto \
    mosquitto-clients

# cleanup
apt-get clean && rm -rf /var/lib/apt/lists/*

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
