#!/bin/bash
set -e

#
# Led the act LED blink
# - see LED0 variable
#
# Author: cdeck3r
#

# Params: none

# Exit codes
# >0 if script breaks

# this directory is the script directory
SCRIPT_DIR="$(
    cd "$(dirname "$0")" || exit
    pwd -P
)"
cd "$SCRIPT_DIR" || exit
# shellcheck disable=SC2034
SCRIPT_NAME=$0

# variables
PATTERN=$1 # default
LED0=/sys/class/leds/led0/trigger

# allowed values for PATTERN
ALLOWED_PATTERN="none rc-feedback kbd-scrolllock kbd-numlock kbd-capslock kbd-kanalock kbd-shiftlock kbd-altgrlock kbd-ctrllock kbd-altlock kbd-shiftllock kbd-shiftrlock kbd-ctrlllock kbd-ctrlrlock timer oneshot heartbeat backlight gpio cpu cpu0 cpu1 cpu2 cpu3 default-on input panic actpwr mmc1 mmc0 rfkill-any rfkill-none rfkill0 rfkill1"

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
    echo "Usage: ${SCRIPT_NAME} [pattern]"
    echo ""
    echo "Allowed pattern:"
    echo "${ALLOWED_PATTERN}"
}

# verfies the script runs as ${USER}
check_user() {
    local CURR_USER

    CURR_USER=$(id --user --name)
    if [ "${CURR_USER}" != "${USER}" ]; then
        return 1
    fi

    return 0
}

#####################################################
# Main program
#####################################################

### Basic checks ###
assert_on_raspi

# check NODE var
if [ -z "$PATTERN" ]; then
    log_echo "WARN" "No blink pattern provided."
    [ -f "${LED0}" ] && {
        log_echo "INFO" "Set to default [mmc0]."
        echo mmc0 | sudo tee "${LED0}"
    }
    exit 0
fi

echo "${ALLOWED_PATTERN}" | grep "${PATTERN}" || {
    echo "Pattern not valid: ${PATTERN}"
    usage
    exit 1
}

[ -f "${LED0}" ] && {
    log_echo "INFO" "Set pattern: ${PATTERN}"
    echo "${PATTERN}" | sudo tee "${LED0}"
}

exit 0
