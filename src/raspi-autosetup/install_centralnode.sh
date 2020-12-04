#!/bin/bash
set -e

#
# Install scanner software for centralnodes
#
# Author: cdeck3r
#

# Params: none

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
