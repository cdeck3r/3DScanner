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
BRANCH_FILE="/boot/BRANCH"

# resolve avahi name conflict by restarting avahi-daemon
# run cronjob after each boot-up
JOBFILE_DIR="/root"
JOBFILE="avahi-resolve-name-conflict.sh"
JOBFILE_PATH="${JOBFILE_DIR}/${JOBFILE}"

#####################################################
# Include Helper functions
#####################################################

# no args
assert_on_raspi() {
    # check we are on Raspi
    MACHINE=$(uname -m)
    if [[ "$MACHINE" != arm* ]]; then
        echo "ERROR: We are not on an arm plattform: ${MACHINE}"
        exit 1
    fi
}

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

# Writes jobfile
# Test for name conflict and restarts avahi service
write_avahi_name_conflict_jobfile() {
    local jobfile_path=$1

    cat <<'EOF' >"${jobfile_path}"
#!/bin/bash

#
# Tests for avahi hostname conflict
# and restarts avahi-daemon, if necessary
#
# Author: cdeck3r
#

# shellcheck disable=SC2034
SCRIPT_NAME=$0

# run 10 times, wait 60s per run -> total 10min
for i in {1..10}; do
    echo "${SCRIPT_NAME} iteration ${i}"
    systemctl status avahi-daemon.service --no-pager --full | grep -i conflict && {
        echo "Found avahi name conflict. Will restart avahi."
        systemctl restart avahi-daemon.service
    }
    sleep 60
done
EOF
    chmod 700 "${jobfile_path}" || { echo "Could not change file permissions: ${jobfile_path}"; }
}

# cronjob to handle the avahi bug
# see: https://github.com/lathiat/avahi/issues/117
avahi_resolve_name_conflict() {
    local logfile
    logfile="/tmp/${JOBFILE}.log"

    # avahi-resolve-name-conflict.sh - remove from crontab
    crontab -l | grep -v "${JOBFILE}" | crontab - || { echo "Ignore error: $?"; }

    write_avahi_name_conflict_jobfile "${JOBFILE_PATH}"
    [ -f "${JOBFILE_PATH}" ] || {
        echo "File does not exist: ${JOBFILE_PATH}"
    }

    # install cronjob - run at boot-up
    (
        crontab -l
        echo "@reboot sleep 60 && ${JOBFILE_PATH} > ${logfile} 2>&1"
    ) | crontab - || { echo "Error adding cronjob. Code: $?"; }

    # start the job in the background
    ${JOBFILE_PATH} &
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
    apt-get update --allow-releaseinfo-change -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false
    apt-get install -y git
}

# we can hard code the repo URL, because this script
# is in the same repo: so this script and the repo are strongly connected
clone_repo() {
    local branch=$1

    # set default
    [ -z "${branch}" ] && { branch="master"; }
    git clone --branch "${branch}" ${REPO}
}

#####################################################
# Main program
#####################################################

assert_on_raspi

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

# avahi resolve name conflict
avahi_resolve_name_conflict
systemctl restart cron.service

# install system sw
install_sys_sw

# download autosetup scripts from branch
BRANCH="master" # default
if [ -f "${BRANCH_FILE}" ]; then
    BRANCH=$(head -1 "${BRANCH_FILE}")
fi
clone_repo "${BRANCH}"

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
