#!/bin/bash
# shellcheck disable=SC1090

#
# Recent shot statistics
#
# 1.
# Computes the time difference between the scanner's
# shutter button and save-images last-saved
# 2.
# Number of last-recent images
# 3.
# Jitter: Time diff between oldest and newest recently stored image.
# Assumes that all camnodes have sync'ed clocks.
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
DIFF_SEC_THR=60 # allowed max time diff between shutter and last-saved

MQTT_BROKER="" # set empty

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

# error counter
((err_cnt = 0))

SKIP_CHECK=$(
    true
    echo $?
)
precheck "${SKIP_CHECK}"

diag "${HR}"
diag "Time difference: shutter button and last-saved images"
diag "${HR}"

TOPIC='scanner/apparatus/cameras/last-button-push'
LAST_BUTTON_PUSH="mosquitto_sub -v -h ${MQTT_BROKER} -t ${TOPIC} -W 2"
LAST_BUTTON_PUSH_EXE=$(${LAST_BUTTON_PUSH})
is $? 0 "Retrieve last-button-push datetime"
LAST_BUTTON_PUSH_RES=$(echo "${LAST_BUTTON_PUSH_EXE}" | head -1)
echo "${LAST_BUTTON_PUSH_RES}"

TOPIC='scanner/apparatus/recent-images/last-saved'
LAST_SAVED="mosquitto_sub -v -h ${MQTT_BROKER} -t ${TOPIC} -W 2"
LAST_SAVED_EXE=$(${LAST_SAVED})
is $? 0 "Retrieve last-saved datetime"
LAST_SAVED_RES=$(echo "${LAST_SAVED_EXE}" | head -1)
echo "${LAST_SAVED_RES}"

# compute diff
LAST_BUTTON_PUSH_DT=$(echo "${LAST_BUTTON_PUSH_RES}" | cut -d' ' -f2)
LAST_SAVED_DT=$(echo "${LAST_SAVED_RES}" | cut -d' ' -f2)

last_button_push_sec=$(date -d"${LAST_BUTTON_PUSH_DT}" +"%s")
last_saved_sec=$(date -d"${LAST_SAVED_DT}" +"%s")

((diff_sec = last_saved_sec - last_button_push_sec))
if ((diff_sec <= DIFF_SEC_THR)); then
    pass "Time difference: ${diff_sec} seconds"
else
    fail "Time difference: ${diff_sec} seconds"
    ((err_cnt += 1))
fi

diag " "

diag "${HR}"
diag "Number of last-recent images"
diag "${HR}"
TOPIC='scanner/apparatus/recent-images/image-count'
IMAGE_COUNT="mosquitto_sub -v -h ${MQTT_BROKER} -t ${TOPIC} -W 2"
IMAGE_COUNT_EXE=$(${IMAGE_COUNT})
is $? 0 "Retrieve scanner's last image-count"
IMAGE_COUNT_RES=$(echo "${IMAGE_COUNT_EXE}" | head -1)
echo "${IMAGE_COUNT_RES}"

IMAGE_COUNT_VAL=$(echo "${IMAGE_COUNT_RES}" | cut -d' ' -f2)
((IMAGE_COUNT_VAL > 0)) || {
    fail "No recent images found."
    ((err_cnt += 1))
}

diag " "

diag "${HR}"
diag "Jitter between recent images"
diag "${HR}"

skip 0 "(TODO) Not implemented yet" || {
    fail "always"
}

# Summary stats
diag "${HR}"
((err_cnt == 0)) && { diag "${GREEN}[SUCCESS]${NC} - Stats is looking good"; }
if ((err_cnt == 1)); then
    diag "${YELLOW}[WARNING]${NC} - Found problem. Check output."
elif ((err_cnt > 1)); then
    diag "${RED}[FAIL]${NC} - Severe problem found. Check output."
fi
diag "${HR}"
