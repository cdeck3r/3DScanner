#!/bin/bash
set -e

#
# rns - remote node setup for a list of nodes
#
# It consumes the from pipe.
#
# Author: cdeck3r
#

# Params:
# $1 - directory containing files

# Exit codes
# 1 - if precond not satisfied
# 2 - if process breaks

# this directory is the script directory
SCRIPT_DIR="$(
    cd "$(dirname "$0")" || exit
    pwd -P
)"
cd "$SCRIPT_DIR" || exit
# shellcheck disable=SC2034
SCRIPT_NAME=$0

# variables
FILE_DIR=$1

#####################################################
# Include Helper functions
#####################################################

#####################################################
# Main program
#####################################################

[ -e "${SCRIPT_DIR}/rns.sh" ] || {
    echo "Could not find rns.sh in ${SCRIPT_DIR}."
    exit 1
}

[ -d "${FILE_DIR}" ] || {
    echo "File directory does not exist: ${FILE_DIR}"
    exit 1
}

if [ -p /dev/stdin ]; then
    echo "Read node addresses from pipe"
    # If we want to read the input line by line
    while IFS= read -r addr; do
        echo "Start rns for node: ${addr}"
        "${SCRIPT_DIR}/rns.sh" "${FILE_DIR}" "${addr}" || {
            echo "ERROR: Cannot remotely setup node: ${addr}"
            echo ""
        }
    done
else
    echo "ERROR: No input pipe found."
    exit 2
fi
