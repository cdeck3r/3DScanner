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

usage() {
    echo "Usage: ${SCRIPT_NAME} [pattern]"
    echo ""
    echo "Allowed pattern:"
    echo "${ALLOWED_PATTERN}"
}

#####################################################
# Main program
#####################################################

### Basic checks ###

# check NODE var
if [ -z "$PATTERN" ]; then
    echo "No blink pattern provided."
    [ -f "${LED0}" ] && {
        echo "Set to default [mmc0]."
        echo mmc0 | sudo tee "${LED0}"
    }
    usage
    exit 1
fi

[ -f "${LED0}" ] && {
    echo "Set pattern: "
    echo "${PATTERN}" | sudo tee "${LED0}"
}
