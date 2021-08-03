#!/bin/bash
# shellcheck disable=SC1090

#
# Runs image housekeeping
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

[ -f "${SCRIPT_DIR}/common_vars.conf" ] || {
    echo "Could find required config file: common_vars.conf"
    echo "Abort."
    exit 1
}
[ -f "${SCRIPT_DIR}/tap-functions.sh" ] || {
    echo "Could find required file: tap-functions.sh"
    echo "Abort."
    exit 1
}

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

SKIP_CHECK=$(
    true
    echo $?
)
precheck "${SKIP_CHECK}"

diag "${HR}"
diag "Run housekeeping for image files"
diag "${HR}"

HK_JOBS=$(crontab -l | grep housekeeping.sh | cut -d' ' -f 6- | cut -d'>' -f1)
mapfile -t HK_JOBS_ARRAY < <(echo "${HK_JOBS}")

for job in "${HK_JOBS_ARRAY[@]}"; do
    #run the job
    ${job} || { fail "Error running housekeeping job."; continue; }
    is $? 0 "Run housekeeping job"
    FILE_DELETED=$(grep "Deleted files:" "${HK_LOG_FILE}" | tail -n1)
    is $? 0 "Collect log information"
    diag "${FILE_DELETED}"
done

