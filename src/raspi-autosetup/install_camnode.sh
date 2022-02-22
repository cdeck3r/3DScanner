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
REPO_DIR="/boot/autosetup/3DScanner"
HOMIE_NODES_DIR="${REPO_DIR}/src/homie-nodes"
HOMIE_CAMNODE_DIR="${HOMIE_NODES_DIR}/homie-camnode"
HOMIE_CAMNODE_USER_DIR="${USER_HOME}/$(basename ${HOMIE_CAMNODE_DIR})"
SERVICE_INSTALL_SCRIPT="${HOMIE_NODES_DIR}/install_homie_service.sh"
USER_ID="$(id -u ${USER})"

# variables for housekeeping
HOUSEKEEPING_INSTALL_DIR="${REPO_DIR}/src/housekeeping"
HOUSEKEEPING_USER_DIR="${USER_HOME}/housekeeping"
HOUSEKEEPING_INSTALL_SCRIPT="${HOUSEKEEPING_USER_DIR}/install_housekeeping.sh"

RASPI_CONF="/etc/init.d/raspi-config"

#####################################################
# Include Helper functions
#####################################################

# returns true, if the raspi-config overwrites scaling governor
conf_overwrites_governor() {
    grep -q "#echo \"ondemand\"" "${RASPI_CONF}" && return 1
    return 0
}

#####################################################
# Main program
#####################################################

# Avoid scaling governor overwrite, keep it as it is
# 1. check for raspi-config
# 2. modify file, if necessary
{ [[ -f "${RASPI_CONF}" ]] && conf_overwrites_governor; } && {
    echo "WARN: raspi-config overwrites the scaling governor"
    # comment out the setting of scaling governor
    sed "s/echo \"ondemand\"/\#echo \"ondemand\"/" -i "${RASPI_CONF}"
}

# ignore wrong date
apt-get update -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false

apt-get install -y \
    python3-pip \
    mosquitto-clients

# cleanup
apt-get clean && rm -rf /var/lib/apt/lists/*

# additional python packages
pip3 install --force-reinstall pyyaml

# homie convention https://github.com/mjcumming/homie4
pip3 install --force-reinstall 'Homie4==0.3.4' 'paho-mqtt==1.5.0'

# python camera package
pip3 install --force-reinstall picamera

# install homie service; run as ${USER}
# 1. copy homie device software
# 2. enable the service start at boot
# 3. install service
rm -rf "${HOMIE_CAMNODE_USER_DIR}" # cleanup
su -c "cp -r ${HOMIE_CAMNODE_DIR} ${USER_HOME}" "${USER}"

# enable the service start at each Raspi boot-up for the user ${USER}
loginctl enable-linger "${USER}" || { echo "Error ignored: $?"; }
chmod 755 "${SERVICE_INSTALL_SCRIPT}"
su -c "XDG_RUNTIME_DIR=/run/user/${USER_ID} ${SERVICE_INSTALL_SCRIPT}" "${USER}"

# install housekeeping; run as ${USER}
# 1. Remove and re-create user directory for housekeeping
# 2. Copy files into user directory and set credentials for install script
# 3. Run install script as ${USER}
# Restart cron service
rm -rf "${HOUSEKEEPING_USER_DIR}" # cleanup
mkdir "${HOUSEKEEPING_USER_DIR}"
cp -r "${HOUSEKEEPING_INSTALL_DIR}" "$(dirname ${HOUSEKEEPING_USER_DIR})"
chown -R ${USER}:${USER} "${HOUSEKEEPING_USER_DIR}"
chmod 744 "${HOUSEKEEPING_INSTALL_SCRIPT}"
su -c "XDG_RUNTIME_DIR=/run/user/${USER_ID} ${HOUSEKEEPING_INSTALL_SCRIPT} ${USER_HOME}/images" "${USER}"
systemctl restart cron.service
