#!/bin/bash
set -e

#
# Runs the autosetup
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
cd "$SCRIPT_DIR" || exit
# shellcheck disable=SC2034
SCRIPT_NAME=$0

# variables
NODETYPE="node" # default
REPO="https://github.com/cdeck3r/3DScanner.git"
USER=pi
USER_HOME="/home/${USER}"
INSTALL_SCRIPT_DIR="${SCRIPT_DIR}/3DScanner/src/raspi-autosetup"

# resolve avahi name conflict by restart
# .service and .sh files are created by autosetup.sh 
SERVICE_UNIT_DIR="/lib/systemd/system"
SERVICE_UNIT_FILE="avahi-resolve-name-conflict.service"
SERVICE_UNIT_FILE_PATH="${SERVICE_UNIT_DIR}/${SERVICE_UNIT_FILE}"
SERVICE_FILE_DIR="/root"
SERVICE_FILE="avahi-resolve-name-conflict.sh"
SERVICE_FILE_PATH="${SERVICE_FILE_DIR}/${SERVICE_FILE}"


#####################################################
# Include Helper functions
#####################################################

# enables the picamera on camnode
# reboots afterwards
enable_camera() {
    local NODETYPE=$1

    if [ "${NODETYPE}" = "CAMNODE" ]; then
        # if enabled do nothing, otherwise enable it
        [[ $(raspi-config nonint get_camera) -eq 0 ]] || {
            raspi-config nonint do_camera 0
            shutdown -r now
        }
    else
        # disable camera
        raspi-config nonint do_camera 1
    fi

}

# copy from booter.sh (violates DRY)
# At booter.sh time, the nodetype is not known
set_node_name() {
    # src: https://github.com/nmcclain/raspberian-firstboot/blob/master/examples/simple_hostname/firstboot.sh
    local NEW_NAME=$1

    if [ -e /sys/class/net/eth0 ]; then
        # shellcheck disable=SC2002
        MAC=$(cat /sys/class/net/eth0/address | tr -d ':')
    else
        MAC="000000000000"
    fi

    NEW_NAME=$(echo "${NEW_NAME}" | tr '[:upper:]' '[:lower:]')
    NEW_NAME=${NEW_NAME}-${MAC}
    CURR_HOSTNAME=$(hostname)

    if [ "${CURR_HOSTNAME}" != "${NEW_NAME}" ]; then
        echo "${NEW_NAME}" >/etc/hostname
        sed -i "s/${CURR_HOSTNAME}/${NEW_NAME}/g" /etc/hosts
        hostname "${NEW_NAME}"
        # restart avahi
        systemctl restart avahi-daemon.service
    fi
}

# publish SSH service via avahi
publish_ssh_service() {
    local SSH_SERVICE_FILE
    SSH_SERVICE_FILE="/etc/avahi/services/ssh.service"

    cat <<EOF >"${SSH_SERVICE_FILE}"
<service-group>

  <name replace-wildcards="yes">%h</name>

  <service>
    <type>_ssh._tcp</type>
    <port>22</port>
  </service>

</service-group>
EOF
    chmod 644 "${SSH_SERVICE_FILE}"
    # restart avahi
    systemctl restart avahi-daemon.service
}

# service file 
# It tests for the conflict and restarts avahi service
write_service_file() {
    local service_file_path=$1

    cat << EOF > "${service_file_path}"
#!/bin/bash

#
# Tests for avahi hostname conflict 
# and restarts avahi-daemon, if necessary
#
# Author: cdeck3r
#

systemctl status avahi-daemon.service --no-pager --full | grep -i conflict && { echo "Found avahi name conflict. Will restart avahi."; systemctl restart avahi-daemon.service; }
EOF

    chmod 755 "${service_file_path}" || { echo "Could not change file permissions: ${service_file_path}"; }
}

# service unit file for the avahi name conflict resolution
write_service_unit_file() {
    local service_unit_file_path=$1
    local service_file_path=$2

    cat << EOF > "${service_unit_file_path}"
[Unit]
Description=Avahi name conflict resolver
After=network.target
Before=rc-local.service
ConditionFileNotEmpty=${service_file_path}

[Service]
Type=simple
Restart=always
RestartSec=300
ExecStart=${service_file_path}

[Install]
WantedBy=multi-user.target
EOF

    chmod 644 "${service_unit_file_path}" || { echo "Could not change file permissions: ${service_unit_file_path}"; }
}

# aux service to handle the avahi bug
# see: https://github.com/lathiat/avahi/issues/117
avahi_resolve_name_conflict() {
    local SYSTEMCTL

    SYSTEMCTL="systemctl --no-pager --no-legend"

    # test
    FOUND_SERVICE=$(${SYSTEMCTL} list-unit-files | grep -c "${SERVICE_UNIT_FILE}" || { echo "Error ignored: $?"; })

    echo "Found instances of ${SERVICE_UNIT_FILE} running: ${FOUND_SERVICE}"
    # stop / remove
    ${SYSTEMCTL} stop "${SERVICE_UNIT_FILE}" || { echo "Error ignored: $?"; }
    ${SYSTEMCTL} disable "${SERVICE_UNIT_FILE}" || { echo "Error ignored: $?"; }

    # (re)place the new service and correct file permissions
    write_service_file "${SERVICE_FILE_PATH}"
    write_service_unit_file "${SERVICE_UNIT_FILE_PATH}" "${SERVICE_FILE_PATH}"

    # start and enable new service
    #systemctl daemon-reload || { echo "Error ignored: $?"; }
    ${SYSTEMCTL} start "${SERVICE_UNIT_FILE}" || { echo "Error ignored: $?"; }
    ${SYSTEMCTL} enable "${SERVICE_UNIT_FILE}" || { echo "Error ignored: $?"; }

    # we expect the service enabled
    STATE=$(${SYSTEMCTL} is-enabled "${SERVICE_UNIT_FILE}")

    if [ "${STATE}" != "enabled" ]; then
        echo "Service not enabled: ${SERVICE_UNIT_FILE}"
    fi
}


# Depending on NODETYPE, the this function installs
# the ssh keys in the respective directories and
# changes the permissions accordingly.
install_sshkeys() {
    local NODETYPE=$1

    mkdir -p ${USER_HOME}/.ssh
    chown ${USER}:${USER} ${USER_HOME}/.ssh
    chmod 700 ${USER_HOME}/.ssh

    # install public key
    SSH_KEYFILE=$(echo "${NODETYPE}.pub" | tr '[:upper:]' '[:lower:]')
    cp "${SSH_KEYFILE}" ${USER_HOME}/.ssh/authorized_keys
    chmod 644 ${USER_HOME}/.ssh/authorized_keys
    chown ${USER}:${USER} ${USER_HOME}/.ssh/authorized_keys

    if [ "${NODETYPE}" = "CENTRALNODE" ]; then
        # install the private (identity) key from the autosetup archive
        SSH_KEYFILE=$(find "${SCRIPT_DIR}" -type f -name "*.priv")
        cp "${SSH_KEYFILE}" ${USER_HOME}/.ssh/id_rsa # default, see man ssh -i option
        chmod 600 ${USER_HOME}/.ssh/id_rsa
        chown ${USER}:${USER} ${USER_HOME}/.ssh/id_rsa
    fi
}

# Edits /etc/ssh/sshd_config adding the following entries
# ChallengeResponseAuthentication no
# PasswordAuthentication no
# UsePAM no
#
# Source: https://www.raspberrypi.org/documentation/configuration/security.md
deactivate_user_login() {
    local SSHD_CONFIG
    local TEMPFILE

    SSHD_CONFIG=/etc/ssh/sshd_config
    TEMPFILE=$(mktemp)

    # remove the line, directly modify the file
    sed --in-place '/^ChallengeResponseAuthentication/d' "${SSHD_CONFIG}"
    sed --in-place '/^PasswordAuthentication/d' "${SSHD_CONFIG}"
    sed --in-place '/^UsePAM/d' "${SSHD_CONFIG}"

    {
        echo "ChallengeResponseAuthentication no"
        echo "PasswordAuthentication no"
        echo "UsePAM no"
    } >>"${SSHD_CONFIG}"

    # This method ensures we don't repeatly add the same lines
    uniq "${SSHD_CONFIG}" >"${TEMPFILE}"
    cat "${TEMPFILE}" >"${SSHD_CONFIG}"
    rm -rf "${TEMPFILE}"
}

# install system software
install_sys_sw() {
    # src: https://github.com/nmcclain/raspberian-firstboot/blob/master/examples/apt_packages/firstboot.sh
    # update apt cache, ingore "Release file... is not valid yet." error
    apt-get update -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false
    apt-get install -y git
}

# we can hard code the repo URL, because this script
# is in the same repo: so this script and the repo are strongly connected
clone_repo() {
    git clone ${REPO}
}

#####################################################
# Main program
#####################################################

# check for NODETYPE file
if [ -f "${SCRIPT_DIR}"/NODETYPE ]; then
    NODETYPE=$(head -1 "${SCRIPT_DIR}"/NODETYPE)
    NODETYPE=$(echo "${NODETYPE}" | tr '[:lower:]' '[:upper:]')
fi

# check NODETYPE var
if [ -z "$NODETYPE" ]; then
    echo "No nodetype provided. Fall back to default."
    # default
    NODETYPE="node"
fi

# basic config
enable_camera "${NODETYPE}"
set_node_name "${NODETYPE}"

# setup ssh
install_sshkeys "${NODETYPE}"
publish_ssh_service
deactivate_user_login
systemctl reload ssh
avahi_resolve_name_conflict

# install system sw
install_sys_sw

# download autosetup scripts
clone_repo

# run install_*.sh
# Note: set -e is given at script start --> if there is an error,
# the script stops and returns to the caller
find "${INSTALL_SCRIPT_DIR}" -type f -name "*.sh" -print0 | xargs -0 chmod 700

cmd="${INSTALL_SCRIPT_DIR}/install_commons.sh"
${cmd}

if [ ${NODETYPE} = "CAMNODE" ]; then
    cmd="${INSTALL_SCRIPT_DIR}/install_camnode.sh"
    ${cmd}
elif [ ${NODETYPE} = "CENTRALNODE" ]; then
    cmd="${INSTALL_SCRIPT_DIR}/install_centralnode.sh"
    ${cmd}
else
    echo "Unknown nodetype: ${NODETYPE}. Nothing to do."
fi

# we always return successfully
# back to booter.sh
exit 0
