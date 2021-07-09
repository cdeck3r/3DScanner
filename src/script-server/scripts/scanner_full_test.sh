#!/bin/bash
# shellcheck disable=SC1090

#
# Scanner full test runs a sequence of test functions
#
# Author: cdeck3r
#

# Params: none

# Exit codes
# 0: at the script's end
# 255: if BAIL_OUT

# this directory is the script directory
SCRIPT_DIR="$(
    cd "$(dirname "$0")" || exit
    pwd -P
)"
cd "$SCRIPT_DIR" || exit
# shellcheck disable=SC2034
SCRIPT_NAME=$0

# Vars

source "${SCRIPT_DIR}/common_vars.conf"
source "${SCRIPT_DIR}/tap-functions.sh"

#####################################################
# Include Helper functions
#####################################################

[ -f "${SCRIPT_DIR}/funcs.sh" ] || {
    echo "Could find required file: funcs.sh"
    echo "Abort."
    exit 1
}
source "${SCRIPT_DIR}/funcs.sh"

#####################################################
# Main program
#####################################################

# first things first
HR=$(hr) # horizontal line
plan_no_plan

diag "${HR}"
diag "Scanner Full Test"
diag "${HR}"

SKIP_CHECK=$(
    true
    echo $?
)
precheck "${SKIP_CHECK}"

diag " "
diag "${HR}"
diag "Basic Tests shall work"
diag "${HR}"

"${SCRIPT_DIR}/check_scanner.sh" || {
    diag "${RED}[FAIL]${NC} - Severe problem when operating the scanner."
    BAIL_OUT "Abort."
}
"${SCRIPT_DIR}/camnodes_online.sh"
"${SCRIPT_DIR}/camnodes_recent-image_datetime.sh"

diag " "
diag "${HR}"
diag "Scanner shoots image and computes stats "
diag "${HR}"

"${SCRIPT_DIR}/shutter-button.sh" &&
    "${SCRIPT_DIR}/recent_shot_stats.sh"

diag "${HR}"
