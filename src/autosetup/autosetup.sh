#!/bin/bash
set -e

#
# Runs the autosetup 
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
NODETYPE="node" # default
REPO="https://github.com/cdeck3r/3DScanner.git"
USER=pi
USER_HOME="/home/${USER}"

#####################################################
# Include Helper functions
#####################################################

# copy from booter.sh (violates DRY)
# At booter.sh time, the nodetype is not known
set_node_name () {
    # src: https://github.com/nmcclain/raspberian-firstboot/blob/master/examples/simple_hostname/firstboot.sh
    local NEW_NAME=$1

    if [ -e /sys/class/net/eth0 ]; then
        MAC=$(cat /sys/class/net/eth0/address | tr -d ':')
    else
        MAC="000000000000"
    fi

    NEW_NAME=$(echo ${NEW_NAME} | tr '[:upper:]' '[:lower:]')
    NEW_NAME=${NEW_NAME}-${MAC}
    CURR_HOSTNAME=$(hostname)
    
    if [ "${CURR_HOSTNAME}" != "${NEW_NAME}" ]; then
        echo "${NEW_NAME}" > /etc/hostname
        sed -i "s/${CURR_HOSTNAME}/${NEW_NAME}/g" /etc/hosts
        hostname "${NEW_NAME}"
        # restart avahi
        systemctl restart avahi-daemon.service
    fi
}

# Depending on NODETYPE, the this function installs 
# the ssh keys in the respective directories and 
# changes the permissions accordingly.
install_sshkeys () {
    local NODETYPE=$1
    
    mkdir -p ${USER_HOME}/.ssh
    chown ${USER}:${USER} ${USER_HOME}/.ssh
    chmod 700 ${USER_HOME}/.ssh
    
    if [ $NODETYPE = "CAMNODE" ]; then 
        SSH_KEYFILE=$(echo ${NODETYPE}.pub | tr '[:upper:]' '[:lower:]')
        cp ${SSH_KEYFILE} ${USER_HOME}/.ssh/authorized_keys
        chmod 644 ${USER_HOME}/.ssh/authorized_keys
        chown ${USER}:${USER} ${USER_HOME}/.ssh/authorized_keys
    fi
    
    if [ $NODETYPE = "CENTRALNODE" ]; then 
        # FIXME: do not NODETYPE in SSH_KEYFILE 
        SSH_KEYFILE=$(echo "CAMNODE" | tr '[:upper:]' '[:lower:]')
        cp ${SSH_KEYFILE} ${USER_HOME}/.ssh/id_rsa # default, see man ssh -i option
        chmod 600 ${USER_HOME}/.ssh/id_rsa
        chown ${USER}:${USER} ${USER_HOME}/.ssh/id_rsa
    fi
}

# install system software
install_sys_sw () {
    # src: https://github.com/nmcclain/raspberian-firstboot/blob/master/examples/apt_packages/firstboot.sh
    # update apt cache, ingore "Release file... is not valid yet." error
    apt-get update -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false
    apt-get install -y git
}

# we can hard code the repo URL, because this script 
# is in the same repo: so this script and the repo are strongly connected 
clone_repo () {
    git clone ${REPO}
}


#####################################################
# Main program
#####################################################

# check for NODETYPE file
if [ -f "${SCRIPT_DIR}"/NODETYPE ]; then
    NODETYPE=$(head -1 "${SCRIPT_DIR}"/NODETYPE)
    NODETYPE=$(echo ${NODETYPE} | tr '[:lower:]' '[:upper:]')
fi

# check NODETYPE var
if [ -z $NODETYPE ]; then
    echo "No nodetype provided. Fall back to default."
    # default
    NODETYPE="node"
fi

# basic config
set_node_name "${NODETYPE}"

# setup ssh 
install_sshkeys "${NODETYPE}"

# install system sw
install_sys_sw

# download autosetup scripts
clone_repo


# run install_*.sh
# ...

# remove
exit 0

