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
# variables for script-server UI
SCRIPT_SERVER_INSTALL_DIR="${REPO_DIR}/src/script-server"
SCRIPT_SERVER_INSTALL_SCRIPT="${SCRIPT_SERVER_INSTALL_DIR}/install_script_server.sh"
SCRIPT_SERVER_USER_DIR="${USER_HOME}/script-server"
# variables for housekeeping
HOUSEKEEPING_INSTALL_DIR="${REPO_DIR}/src/housekeeping"
HOUSEKEEPING_USER_DIR="${USER_HOME}/housekeeping"
HOUSEKEEPING_INSTALL_SCRIPT="${HOUSEKEEPING_USER_DIR}/install_housekeeping.sh"
# variables for reboot
REBOOT_INSTALL_DIR="${REPO_DIR}/src/reboot"
REBOOT_USER_DIR="${USER_HOME}/reboot"
REBOOT_INSTALL_SCRIPT="${REBOOT_USER_DIR}/install_reboot.sh"

# Exit codes
# >0 if script breaks

# this directory is the script directory
SCRIPT_DIR="$(
    cd "$(dirname "$0")" || exit
    pwd -P
)"

#
# Remove / kill cronjobs
# - shutdown: in the root's crontab
# - reboot.sh: kill the pi's reboot.sh job
crontab -l | grep -v 'shutdown' | crontab - || { echo "Ignore error: $?"; }
REBOOT_SH_PID=$(pgrep -f 'reboot.sh') && {
    kill -9 "${REBOOT_SH_PID}"
}

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
pip3 install --force-reinstall tornado

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

# create root, configure and restart nginx
#
# create: take root from conf file
NGINX_ROOT=$(cat "${SCRIPT_DIR}/centralnode_nginx.conf" | sed -e 's/^[[:space:]]*//
' | egrep '^root' | cut -d' ' -f2 | cut -d';' -f1 | head -1)
mkdir -p "${NGINX_ROOT}"
chmod 755 "${NGINX_ROOT}"
chown ${USER}:${USER} "${NGINX_ROOT}"
# ... configure and restart nginx
cp "${SCRIPT_DIR}/centralnode_nginx.conf" /etc/nginx/sites-available/default
chmod 644 /etc/nginx/sites-available/default
chown root:root /etc/nginx/sites-available/default
systemctl restart nginx

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
su -c "cp -r ${HOMIE_APPARATUS_DIR} $(dirname ${HOMIE_APPARATUS_USER_DIR})" "${USER}"
# enable the service start at each Raspi boot-up for the user ${USER}
loginctl enable-linger "${USER}" || { echo "Error ignored: $?"; }
chmod 755 "${SERVICE_INSTALL_SCRIPT}"
su -c "XDG_RUNTIME_DIR=/run/user/${USER_ID} ${SERVICE_INSTALL_SCRIPT}" "${USER}"

# install script-server UI; run as ${USER}
# 1. Download and cp script-server in "${SCRIPT_SERVER_USER_DIR}"
# 2. enable the service start at boot
# 3. install service
rm -rf "${SCRIPT_SERVER_USER_DIR}" # cleanup
# download and copy
wget 'https://github.com/bugy/script-server/releases/download/1.16.0/script-server.zip' -O /tmp/script-server.zip -q
# usually in /home/pi
mkdir "${SCRIPT_SERVER_USER_DIR}"
unzip -q /tmp/script-server.zip -d "${SCRIPT_SERVER_USER_DIR}"
cp -r "${SCRIPT_SERVER_INSTALL_DIR}" "$(dirname ${SCRIPT_SERVER_USER_DIR})"
chmod -R 744 "${SCRIPT_SERVER_USER_DIR}/scripts"
chown -R ${USER}:${USER} "${SCRIPT_SERVER_USER_DIR}"
# cleanup
rm -rf /tmp/script-server.zip
# enable the service start at each Raspi boot-up for the user ${USER}
loginctl enable-linger "${USER}" || { echo "Error ignored: $?"; }
chmod 755 "${SCRIPT_SERVER_INSTALL_SCRIPT}"
su -c "XDG_RUNTIME_DIR=/run/user/${USER_ID} ${SCRIPT_SERVER_INSTALL_SCRIPT}" "${USER}"
systemctl restart cron.service

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
su -c "XDG_RUNTIME_DIR=/run/user/${USER_ID} ${HOUSEKEEPING_INSTALL_SCRIPT} ${NGINX_ROOT}" "${USER}"
systemctl restart cron.service

# install reboot; run as ${USER}
# 1. Remove and re-create user directory for reboot
# 2. Copy files into user directory and set credentials for install script
# 3. Run install script as ${USER}
# 4. Install daily reboot
# Restart cron service
rm -rf "${REBOOT_USER_DIR}" # cleanup
mkdir -p "${REBOOT_USER_DIR}"
cp -r "${REBOOT_INSTALL_DIR}" "$(dirname ${REBOOT_USER_DIR})"
chown -R ${USER}:${USER} "${REBOOT_USER_DIR}"
chmod 744 "${REBOOT_INSTALL_SCRIPT}"
su -c "XDG_RUNTIME_DIR=/run/user/${USER_ID} ${REBOOT_INSTALL_SCRIPT}" "${USER}"
# Install daily reboot at 1:30am
(
    crontab -l
    echo "30 1 * * * /sbin/shutdown -r now"
) | sort | uniq | crontab - || {
    echo "Error adding cronjob. Code: $?"
    exit 2
}
systemctl restart cron.service
