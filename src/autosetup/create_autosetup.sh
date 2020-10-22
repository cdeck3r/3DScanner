#!/bin/bash
set -e

#
# Create the autosetup.zip file
# The archive contains
# - ssh keys
# - NODETYPE definition
# - autosetup.sh
# 
# Author: cdeck3r
#

# Params: nodetype 

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
NODETYPE=$1
AUTOSETUP="${SCRIPT_DIR}"/autosetup.sh


#####################################################
# Include Helper functions
#####################################################

usage () {
    echo "Usage: $SCRIPT_NAME <nodetype>"
    echo "with nodetype = [ CAMNODE | CENTRALNODE ]"
}

#####################################################
# Main program
#####################################################

# check params
if [ -z $NODETYPE ]; then
    echo "Too few arguments"
    usage
    exit 0
fi
NODETYPE=$(echo "${NODETYPE}" | tr [:lower:] [:upper:])
if ! [[ "${NODETYPE}" =~ ^(CAMNODE|CENTRALNODE)$ ]]; then 
    echo "Given <nodetype> not supported: ${NODETYPE}"
    echo ""
    usage
    exit 0
fi

# check for installed program
# Source: https://stackoverflow.com/a/677212
command -v "ssh-keygen" >/dev/null 2>&1 || { echo >&2 "I require ssh-keygen but it's not installed.  Abort."; exit 1; }
command -v "zip" >/dev/null 2>&1 || { echo >&2 "I require zip but it's not installed.  Abort."; exit 1; }

# we need the basic autosetup.sh
if [ ! -d "${AUTOSETUP}" ]; then
    echo "File not found: ${AUTOSETUP}"
    exit 1
fi

# remove
exit 0

# generate ssh keys
# todo

# NODETYPE definition
echo "$NODETYPE" > ./NODETYPE
chmod 644 ./NODETYPE

exit 0