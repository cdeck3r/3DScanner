#!/bin/bash
set -e

#
# Create the autosetup_NODEYPE.zip file
# The archive contains
# - ssh keys
# - NODETYPE definition
# - autosetup.sh
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
AUTOSETUP="${SCRIPT_DIR}"/autosetup.sh
KEYFILE=camnode

#####################################################
# Include Helper functions
#####################################################

# no helper functions

#####################################################
# Main program
#####################################################


# check for installed program
# Source: https://stackoverflow.com/a/677212
command -v "ssh-keygen" >/dev/null 2>&1 || { echo >&2 "I require ssh-keygen but it's not installed.  Abort."; exit 1; }
command -v "zip" >/dev/null 2>&1 || { echo >&2 "I require zip but it's not installed.  Abort."; exit 1; }

# we need the basic autosetup.sh script
if [ ! -f "${AUTOSETUP}" ]; then
    echo "File not found: ${AUTOSETUP}"
    exit 1
fi

# generate ssh keys
ssh-keygen -q -t rsa -f "${SCRIPT_DIR}"/"${KEYFILE}" -N "" -C "CamNode ssh key"

# package
for NODETYPE in "CAMNODE" "CENTRALNODE"
do
    # NODETYPE definition
    echo "$NODETYPE" > "${SCRIPT_DIR}"/NODETYPE
    chmod 644 "${SCRIPT_DIR}"/NODETYPE

    #zip autosetup_NODEYPE.zip
    # autosetup.sh
    # NODETYPE
    # keyfile
    
    if [ "${NODETYPE}" = "CAMNODE" ]; then
        SSH_KEYFILE=${KEYFILE}.pub
    fi

    if [ "${NODETYPE}" = "CENTRALNODE" ]; then
        SSH_KEYFILE=${KEYFILE}
    fi

    # zip "SSH_KEYFILE" NODETYPE "${AUTOSETUP}"
    AUTOSETUP_ZIP=$(echo autosetup_${NODETYPE}.zip | tr '[:upper:]' '[:lower:]')
    rm -rf "${SCRIPT_DIR}"/"${AUTOSETUP_ZIP}"
    echo "Create $AUTOSETUP_ZIP..."
    zip -j "${AUTOSETUP_ZIP}" "$SSH_KEYFILE" "${SCRIPT_DIR}"/NODETYPE "${AUTOSETUP}" 
done

# cleanup
rm -rf "${SCRIPT_DIR}"/NODETYPE
rm -rf "${SCRIPT_DIR}"/"${KEYFILE}"*

exit 0
