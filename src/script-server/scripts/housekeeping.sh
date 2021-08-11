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

# variables
HK_LOG_FILE="/home/pi/log/housekeeping.log"
PARTITION="/"

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

((deleted_files_total = 0))
((error_cnt = 0))
for job in "${HK_JOBS_ARRAY[@]}"; do
    #run the job
    ${job} || { fail "Error running housekeeping job: ${job}"; ((error_cnt+=1)); continue; }
    is $? 0 "Run housekeeping job: ${job}"
    LOG_GREP=$(grep "Deleted files:" "${HK_LOG_FILE}")
    is $? 0 "Collect log information"
    FILES_DELETED=$(echo "${LOG_GREP}" | tail -n1 | cut -d' ' -f10)
    diag "Files deleted: ${FILES_DELETED}"
    [[ "${FILES_DELETED}" =~ ^[0-9]+$ ]] && {
        ((deleted_files_total += FILES_DELETED))
    }    
done



# summary evaluation 
diag "${HR}"
FREE=$(df --output=avail -k "${PARTITION}" | tail -n1 | xargs)

if ((error_cnt > 0)); then
    diag "${RED}[FAIL]${NC} - Problems deleting files during housekeeping."
    diag "${YELLOW}[WARN]${NC} - Check free space [KB]: ${FREE}"
    diag "${HR}"
    exit 1
elif ((deleted_files_total >= 0)); then
    diag "${GREEN}[SUCCESS]${NC} - Files deleted: ${deleted_files_total}"
else
    diag "${NC}[DONE]${NC} - Nothing to do. Files deleted: ${deleted_files_total}"
fi

# free space
diag "${GREEN}[SUCCESS]${NC} - Free space [KB]: ${FREE}"

diag "${HR}"


