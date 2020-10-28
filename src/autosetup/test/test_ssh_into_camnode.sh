#!/bin/bash
set -e

#
# SSH into camnode from 3dsdev 
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
AUTOSETUP_DIR=/tmp/autosetup
AUTOSETUP_ZIP="${SCRIPT_DIR}"/../autosetup_centralnode.zip
USER=root
USER_HOME="/${USER}"
CAMNODE="camnode-dca632b40802"
KEYFILE=${AUTOSETUP_DIR}/camnode

#####################################################
# Include Helper functions
#####################################################

# ...

#####################################################
# Main program
#####################################################

if [ ! -f ${AUTOSETUP_ZIP} ]; then
    echo "Could not find file: ${AUTOSETUP_ZIP}"
    exit 1
fi

if [ "${AUTOSETUP_DIR}" = "${SCRIPT_DIR}" ]; then
    echo "Something is wrong. AUTOSETUP_DIR is the same as SCRIPT_DIR."
    exit 2
fi

rm -rf "${AUTOSETUP_DIR}"
unzip "${AUTOSETUP_ZIP}" -d "${AUTOSETUP_DIR}"

if [ ! -f "${KEYFILE}" ]; then
    echo "Keyfile does not exist: $KEYFILE"
    exit 2
fi

# testcase 
# ssh into $NODE
echo "Correct permissions for keyfile..."
chmod 600 "${KEYFILE}"
chown ${USER}:${USER} "${KEYFILE}"

echo "####################################################"
echo "Run ssh-keyscan to add fingerprint to known_hosts..."
echo "####################################################"
ssh-keyscan -H "${CAMNODE}" > "${AUTOSETUP_DIR}"/known_hosts


echo "####################################################"
echo "ssh into ${CAMNODE}..."
echo "####################################################"
ssh -i "${KEYFILE}" -o UserKnownHostsFile="${AUTOSETUP_DIR}"/known_hosts -t pi@${CAMNODE} "hostname"

echo "####################################################"
echo "ssh into ${CAMNODE}... (without known_hosts)"
echo "####################################################"
rm -f "${AUTOSETUP_DIR}"/known_hosts
ssh -i "${KEYFILE}" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t pi@${CAMNODE} "hostname"

# cleanup
rm -rf "${AUTOSETUP_DIR}"

exit 0