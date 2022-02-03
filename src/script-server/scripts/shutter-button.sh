#!/bin/bash
# shellcheck disable=SC1090

#
# Pushes the scanner's camera shutter-button
# The script publishs a message to scanner/apparatus/cameras/shutter-button
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
YIELD_TIME_SEC=4 #time to wait before starting to save images
MAX_WAIT_SEC_SAVE_IMAGES=30
ENABLE_HOUSEKEEPING=1 # performs image housekeeping before saving images
# retrieve image directory from housekeeping cronjob
WWW_IMG_DIR=$(crontab -l | grep housekeeping.sh | cut -d' ' -f 6- | cut -d'>' -f1 | cut -d' ' -f2 | grep -v tmp)

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

[ -z "${WWW_IMG_DIR}" ] && BAIL_OUT "Could not determine image directory."
[ -d "${WWW_IMG_DIR}" ] || BAIL_OUT "Image directory does not exist: ${WWW_IMG_DIR}"

latest_img_dir() {
    local lid

    # source: https://stackoverflow.com/a/64466737
    lid=$(find "${WWW_IMG_DIR}" -mindepth 1 -maxdepth 1 -type d -printf "%T@\\t%p\\n" | sort -n | cut -f2- | tail -n1)

    echo "${lid}"
}

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
diag "Prepare"
diag "${HR}"

TOPIC='scanner/apparatus/recent-images/last-saved'
LAST_SAVED="mosquitto_sub -v -h ${MQTT_BROKER} -t ${TOPIC} -W 2"
LAST_SAVED_EXE=$(${LAST_SAVED})
is $? 0 "Retrieve last-saved datetime"
LAST_SAVED_RES=$(echo "${LAST_SAVED_EXE}" | head -1)
echo "${LAST_SAVED_RES}"

LAST_SAVED_DT=$(echo "${LAST_SAVED_RES}" | cut -d' ' -f2)
prev_last_saved_sec=$(date -d"${LAST_SAVED_DT}" +"%s")

diag " "

diag "${HR}"
diag "Push scanner's shutter button"
diag "${HR}"

TOPIC="scanner/apparatus/cameras/shutter-button/set"
MSG="push"
BUTTON_PUSH="mosquitto_pub -h ${MQTT_BROKER} -t ${TOPIC} -m ${MSG}"
${BUTTON_PUSH}
is $? 0 "Shutter button pushed"

diag "Button push datetime"
TOPIC="scanner/apparatus/cameras/last-button-push"
LAST_BUTTON_PUSH="mosquitto_sub -v -h ${MQTT_BROKER} -t ${TOPIC} -W 2"
LAST_BUTTON_PUSH_EXE=$(${LAST_BUTTON_PUSH})
is $? 0 "Retrieve button push datetime"
LAST_BUTTON_PUSH_RES=$(echo "${LAST_BUTTON_PUSH_EXE}" | head -1)
echo "${LAST_BUTTON_PUSH_RES}"

diag "Give some time before starting to save all images"
sleep ${YIELD_TIME_SEC}

diag " "
((ENABLE_HOUSEKEEPING)) && {
    ./housekeeping.sh
    diag " "
}

diag "${HR}"
diag "Saving all camera images"
diag "${HR}"

PREV_LATEST_IMG_DIR=$(latest_img_dir)

TOPIC="scanner/apparatus/recent-images/save-all/set"
MSG="run"
SAVE_ALL_IMAGES="mosquitto_pub -h ${MQTT_BROKER} -t ${TOPIC} -m ${MSG}"
${SAVE_ALL_IMAGES}
is $? 0 "Start saving all camera images... wait to complete"

# loop until last-saved changes
((counter = MAX_WAIT_SEC_SAVE_IMAGES))
while ((--counter > 0)); do
    TOPIC='scanner/apparatus/recent-images/last-saved'
    LAST_SAVED="mosquitto_sub -v -h ${MQTT_BROKER} -t ${TOPIC} -W 2"
    LAST_SAVED_EXE=$(${LAST_SAVED})
    is $? 0 "Check # $((MAX_WAIT_SEC_SAVE_IMAGES - counter)): Wait to complete..."
    LAST_SAVED_RES=$(echo "${LAST_SAVED_EXE}" | head -1)
    echo "${LAST_SAVED_RES}"

    # compute diff
    LAST_SAVED_DT=$(echo "${LAST_SAVED_RES}" | cut -d' ' -f2)
    last_saved_sec=$(date -d"${LAST_SAVED_DT}" +"%s")

    ((prev_last_saved_sec != last_saved_sec)) && { break; }

    sleep 1
done
# counter shall not be 0 to indicate success
ok $((counter > 0)) "Save all camera images"
((counter > 0)) || fail "Waiting time exceeded"

## Post-hoc checks
# 1. Check for recent image from each camnode
# 2. print number of downloaded images

## An image was taken recently, if it not older than 10min.
## Only recent images got downloaded by node_recentimages.py
## As a result, we only have recent images in the image directory.
((imgcnt = 0))
((counter > 0)) && {
    # find download dir
    CURR_LATEST_IMG_DIR=$(latest_img_dir)
    isnt "${PREV_LATEST_IMG_DIR}" "${CURR_LATEST_IMG_DIR}" "New image directory created"
    # count images
    imgcnt=$(find "${CURR_LATEST_IMG_DIR}" -type f -printf '.' | wc -c)
    ok $? "Count number of images in ${CURR_LATEST_IMG_DIR}"
    ok $((imgcnt > 0)) "Recent images available: ${imgcnt}"
}

# Summary
diag "${HR}"
((counter == 0)) && { diag "${RED}[FAIL]${NC} - Possible problem. Check output."; }
((counter > 0)) && { diag "${GREEN}[SUCCESS]${NC} - ${imgcnt} images available."; }
diag "${HR}"
