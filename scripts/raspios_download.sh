#!/bin/bash
set -e

#
# Download RasPiOS images
# 
# Author: cdeck3r
#

# Params: none

# Exit codes
# 1: if pre-requisites are not fulfilled
# 2: fatal error prohibiting further progress, see terminal window

# this directory is the script directory
SCRIPT_DIR="$(
    cd "$(dirname "$0")" || exit
    pwd -P
)"
cd "$SCRIPT_DIR" || exit
# shellcheck disable=SC2034
SCRIPT_NAME=$0

# variables
# ... for download
RASPIOS_DIR="/3DScannerRepo/raspios"
RASPIOS_IMAGE_URL='https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2020-08-24/2020-08-20-raspios-buster-armhf-lite.zip'
# 
MOUNT_POINT=/mnt

#####################################################
# Include Helper functions
#####################################################

# ...

#####################################################
# Main program
#####################################################

# check for installed program
# Source: https://stackoverflow.com/a/677212
#command -v "wget" >/dev/null 2>&1 || { echo >&2 "I require wget but it's not installed.  Abort."; exit 1; }

# ensure RASPIOS_DIR exists
mkdir -p "${RASPIOS_DIR}" 
# save current dir on stack
pushd "${RASPIOS_DIR}" >/dev/null
cd "${RASPIOS_DIR}" || { exit 1; } 

# check for image
IMAGE_ZIPFILE=$(basename ${RASPIOS_IMAGE_URL})
if [ ! -f ${IMAGE_ZIPFILE} ]; then
    # download image & unzip
    wget -nH -nd "${RASPIOS_IMAGE_URL}"
    unzip -t ${IMAGE_ZIPFILE} 
    unzip ${IMAGE_ZIPFILE} 
fi

# try to mount
IMAGE_FILE=$(basename -- "${IMAGE_ZIPFILE}")
IMAGE_FILE_EXT="${IMAGE_FILE##*.}"
IMAGE_FILE="${IMAGE_FILE%.*}"
IMAGE_FILE="${IMAGE_FILE}".img

if [ -f "{IMAGE_FILE}" ]; then
    echo "Raspi image exists: ${RASPIOS_DIR}/${IMAGE_FILE}"
else
    echo "Could not find image: ${IMAGE_FILE}"
    # return to current dir from stack
    popd >/dev/null
    exit 2
fi

# return to current dir from stack
popd >/dev/null