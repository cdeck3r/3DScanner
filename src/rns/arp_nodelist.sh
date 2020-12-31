#!/bin/bash
set -e

#
# Outputs a Raspberry Pi node list using arp-scan
# It greps for the following hw addresses
# b8:27:eb Raspberry Pi Foundation
# e4:5f:01 Raspberry Pi Trading Ltd
# dc:a6:32 Raspberry Pi Trading Ltd
#
# Author: cdeck3r
#

# Params: none

# Exit codes
# 1 - if precond not satisfied

# this directory is the script directory
SCRIPT_DIR="$(
    cd "$(dirname "$0")" || exit
    pwd -P
)"
cd "$SCRIPT_DIR" || exit
# shellcheck disable=SC2034
SCRIPT_NAME=$0

# variables
# none

#####################################################
# Include Helper functions
#####################################################

#####################################################
# Main program
#####################################################

command -v arp-scan >/dev/null || {
    echo "Could not find tool: arp-scan"
    exit 1
}

MY_IP=$(hostname -I | cut -d' ' -f1)
MY_MAC=$(cat /sys/class/net/eth0/address)
# 
ARP_SCAN="sudo arp-scan --localnet --plain -t 100 -r 1"
${ARP_SCAN} | grep -v ${MY_MAC} | grep -i "b8:27:eb" | cut -d$'\t' -f1
${ARP_SCAN} | grep -v ${MY_MAC} | grep -i "e4:5f:01" | cut -d$'\t' -f1
${ARP_SCAN} | grep -v ${MY_MAC} | grep -i "dc:a6:32" | cut -d$'\t' -f1

exit 0
