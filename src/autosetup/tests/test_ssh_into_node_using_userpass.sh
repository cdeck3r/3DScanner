#!/bin/bash

#
# SSH into node from 3dsdev
#
# Author: cdeck3r
#

# Params: none

# this directory is the script directory
# shellcheck disable=SC2034
SCRIPT_DIR="$(pwd -P)"
# shellcheck disable=SC2034
SCRIPT_NAME=$0

# param
HOSTNAME=$1

#####################################################
# Tests
#####################################################

SSH_CMD="sshpass -p raspberry ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t pi@${HOSTNAME} hostname"

${SSH_CMD} >/dev/null

exit $?
