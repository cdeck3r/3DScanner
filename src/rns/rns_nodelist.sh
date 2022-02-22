#!/bin/bash
set -e

#
# rns for nodelist - remote node setup (rns) for all nodes in nodelist.log
#
# This script consumes the nodelist.log on the centralnode and runs
# the rns.sh script on all nodes from this list.
#
# Note: run only centralnode
#
# Author: cdeck3r
#

# Params:
# see usage

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
## cmd line args parsed in the main program

## others
DELAY=10                             #default: time in minutes between two node's reboot
PI_USER_PASS="raspberry"             #default
PING_ENABLED=0                       #default
ARMED='false'                        #default, i.e. it perfoms a dry run, override with -a option
NODELIST="/home/pi/log/nodelist.log" # exists on centralnode

#####################################################
# Include Helper functions
#####################################################

[ -f "${SCRIPT_DIR}/funcs.sh" ] || {
    echo "Could find required file: funcs.sh"
    echo "Abort."
    exit 1
}
# shellcheck disable=SC1090
source "${SCRIPT_DIR}/funcs.sh"

usage() {
    echo ""
    echo "$(basename "${SCRIPT_NAME}") updates all nodes from nodelist.log"
    echo "If started with no arguments, it will perform a dry run."
    echo ""
    echo "Usage: ${SCRIPT_NAME} [-a] [file directory]"
    echo ""
    echo "Arguments:"
    echo "-a       - if provided, script is armed."
    echo "file dir - directory with autosetup files for upload to node"
    echo ""
}

#####################################################
# Main program
#####################################################

assert_on_raspi
assert_on_centralnode

# Check: rns.sh
{ [[ -f "${SCRIPT_DIR}/rns.sh" ]] && [[ -x "${SCRIPT_DIR}/rns.sh" ]]; } || {
    log_echo "ERROR" "Script does not exist: ${SCRIPT_DIR}/rns.sh"
    exit 1
}

# parse options
while getopts 'a' flag; do
    case "${flag}" in
    a) ARMED='true' ;;
    *) usage ;;
    esac
done
[[ "${ARMED}" == 'false' ]] && usage
[[ "${ARMED}" == 'true' ]] && log_echo "INFO" "Run mode is ARMED=${ARMED}. All commands will run."
#shellcheck disable=SC2124
FILE_DIR="${@:$OPTIND:1}"

# some checks first
# shellcheck disable=SC2153
[ -z "${SSHPASS}" ] && {
    log_echo "WARN" "Env var SSHPASS not set. Will use default value."
    SSHPASS="${PI_USER_PASS}"
    log_echo "INFO" "SSHPASS set to default password: ${PI_USER_PASS}"
}
export SSHPASS="${SSHPASS}"

# Check: FILE_DIR
if ! [ -z "${FILE_DIR}" ]; then
    [ -d "${FILE_DIR}" ] || {
        log_echo "ERROR" "File directory does not exist: ${FILE_DIR}"
        exit 1
    }
    log_echo "INFO" "Update autosetup files for all nodes from directory: ${FILE_DIR}"
else
    log_echo "WARN" "No update for autosetup files. Re-run autosetup for all nodes."
fi

# Check: PING_ENABLED
log_echo "INFO" "Ping nodes set to PING_ENABLED=${PING_ENABLED}"
export PINGNODE="${PING_ENABLED}"

# Check: NODELIST
[[ -f "${NODELIST}" ]] || {
    log_echo "ERROR" "Nodelist not found: ${NODELIST}"
    exit 2
}
NODELIST_NODE_COUNT=$(sort -u "${NODELIST}" | wc -l)
log_echo "INFO" "Number of nodes: ${NODELIST_NODE_COUNT}"

RNS_CMD="${SCRIPT_DIR}/rns.sh \$1 \$(( \$0 * ${DELAY} )) ${FILE_DIR}"
if [[ "${ARMED}" == "true" ]]; then
    sort -u "${NODELIST}" | cat -b | cut -d$'\t' -f1,3 | xargs -n2 bash -c "${RNS_CMD}"
else
    log_echo "INFO" "DRY RUN START: rns commands to run"
    sort -u "${NODELIST}" | cat -b | cut -d$'\t' -f1,3 | xargs -n2 bash -c "echo ${RNS_CMD}"
    log_echo "INFO" "DRY RUN END"
fi

exit 0
