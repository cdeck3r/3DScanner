#!/bin/bash
set -e

#
# Download *ALL* images from Homie4 mqtt topics
#
# Author: cdeck3r
#

# Params: none

# this directory is the script directory
# shellcheck disable=SC2034
SCRIPT_DIR="$(pwd -P)"
# shellcheck disable=SC2034
SCRIPT_NAME=$0

# param
MQTT_BROKER=$1
MQTT_PORT=$2
DOWNLOAD_DIR=$3

# other vars
WAIT_TIME=2

#####################################################
# Include Helper functions
#####################################################

#####################################################
# Main
#####################################################

### Basic checks ###

if [ -z "${MQTT_BROKER}" ]; then
    echo "No broker provided."
    exit 1
fi

if [ -z "${MQTT_PORT}" ]; then
    echo "No port port provided."
    exit 1
fi

if [ -z "${DOWNLOAD_DIR}" ]; then
    echo "No download directory provided."
    exit 1
fi

# check tools
TOOLS=('mosquitto_sub')
for t in "${TOOLS[@]}"; do
    command -v "${t}" >/dev/null || {
        echo "Could not find tool: $t"
        exit 1
    }
done

# Example:
#   mosquitto_sub
#       -h centralnode-dca632b407ff.local
#       -p 1883
#       -t scanner/camnode-dca632b40802/recent-image/file
#       -C 1
#

CAMNODES="mosquitto_sub -h ${MQTT_BROKER} -p ${MQTT_PORT} -v -t scanner/+/\$homie -W ${WAIT_TIME}"
CAMNODE_IMG="mosquitto_sub -h ${MQTT_BROKER} -p ${MQTT_PORT} -t scanner/{}/recent-image/file -W ${WAIT_TIME} -C 1 > ${DOWNLOAD_DIR}/{}_recent-image.json"

${CAMNODES} | cut -d'/' -f2 | xargs -d '\n' -I{} sh -c "${CAMNODE_IMG}"

exit $?
