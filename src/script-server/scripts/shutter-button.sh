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
MAX_WAIT_SEC_SAVE_IMAGES=30 # seconds to repeatedly try downloading images
MAX_RUNS_BUTTON_RELEASE=5 # number of runs to test cameras in button release state
YIELD_TIME_SEC=1 # time to wait before between each run
ENABLE_HOUSEKEEPING=1 # performs image housekeeping before saving images
# retrieve image directory from housekeeping cronjob
WWW_IMG_DIR=$(crontab -l | grep housekeeping.sh | cut -d' ' -f 6- | cut -d'>' -f1 | cut -d' ' -f2 | grep -v tmp)
IMG_SUFFIX="png"

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

diag "Wait until shutter button release on all camnode"
TOPIC="scanner/+/camera/shutter-button"

((counter = MAX_RUNS_BUTTON_RELEASE))
((release = 0))
while ((--counter >= 0)); do
    CAMNODE_BUTTON_RELEASE="mosquitto_sub -v -h ${MQTT_BROKER} -t ${TOPIC} -W 2"
    CAMNODE_BUTTON_RELEASE_EXE=$(${CAMNODE_BUTTON_RELEASE})
    is $? 0 "Check all camnodes' shutter button status... # $((MAX_RUNS_BUTTON_RELEASE - counter))"

    mapfile -t CAMNODE_BUTTON_RELEASE_ARRAY < <(echo "${CAMNODE_BUTTON_RELEASE_EXE}" | cut -d' ' -f2)
    # iterate through all camnodes
    for camnode_button in "${CAMNODE_BUTTON_RELEASE_ARRAY[@]}"; do
        if [ "${camnode_button}" == "release" ]; then
            ((release = 1))
        else
            # at least one camnode shutton button is not released
            ((release = 0))
            break
        fi
    done
    if ((release == 1)); then
        # all camnode buttons are released
        break 
    else
        sleep ${YIELD_TIME_SEC}
    fi
done
# counter shall not be 0 to indicate success
is $((counter >= 0)) 1 "All cameras done takening images"
((counter >= 0)) || fail "Waiting time for cameras exceeded"


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
is $((counter > 0)) 1 "Save all camera images"
((counter > 0)) || fail "Waiting time exceeded"

diag "${HR}"
diag "Zip all camera images"
diag "${HR}"
# zip all images
CURR_LATEST_IMG_DIR=$(latest_img_dir)
CURR_LATEST_IMG_DIRNAME=$(basename "${CURR_LATEST_IMG_DIR}")
find "${CURR_LATEST_IMG_DIR}" -type f -name "*.${IMG_SUFFIX}" | zip -q -0 "${CURR_LATEST_IMG_DIR}/${CURR_LATEST_IMG_DIRNAME}.zip" -@
ok $? "Zip all downloaded image files"

diag "${HR}"
diag "Post-hoc checks"
diag "${HR}"

## Post-hoc checks
# 1. Check for recent image from each camnode
# 2. print number of downloaded images
# 3. Check zip file integrity

## An image was taken recently, if it not older than 10min.
## Only recent images got downloaded by node_recentimages.py
## As a result, we only have recent images in the image directory.
((imgcnt = 0))
((counter > 0)) && {
    # find download dir
    CURR_LATEST_IMG_DIR=$(latest_img_dir)
    if [[ "${PREV_LATEST_IMG_DIR}" == "${CURR_LATEST_IMG_DIR}" ]]; then
        fail "Expected a new image directory, but found old one: ${PREV_LATEST_IMG_DIR}"
    else
        isnt "${PREV_LATEST_IMG_DIR}" "${CURR_LATEST_IMG_DIR}" "New image directory found: ${CURR_LATEST_IMG_DIR}"
    fi
    # count images
    imgcnt=$(find "${CURR_LATEST_IMG_DIR}" -type f -name "*.${IMG_SUFFIX}" -printf '.' | wc -c)
    ok $? "Count number of images in ${CURR_LATEST_IMG_DIR}"
    is $((imgcnt > 0)) 1 "Recent images available: ${imgcnt}"
}

# Check zip file integrity
zip -q -T "${CURR_LATEST_IMG_DIR}/${CURR_LATEST_IMG_DIRNAME}.zip"
ok $? "Check image zip file integrity"

# Summary
diag "${HR}"
((counter == 0)) && { diag "${RED}[FAIL]${NC} - Possible problem. Check output."; }
((counter > 0)) && { diag "${GREEN}[SUCCESS]${NC} - ${imgcnt} images available."; }
diag "${HR}"
