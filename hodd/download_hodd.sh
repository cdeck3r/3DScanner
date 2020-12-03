#!/bin/bash
set -e

#
# Download HoDD - Homie Device Discovery
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
HODD_DIR="/3DScannerRepo/hodd"
HODD_URL='https://github.com/rroemhild/hodd/archive/v0.4.0.zip'

#####################################################
# Include Helper functions
#####################################################

# ...

#####################################################
# Main program
#####################################################

# check for installed program
# Source: https://stackoverflow.com/a/677212
command -v "wget" >/dev/null 2>&1 || {
    echo >&2 "I require wget but it's not installed.  Abort."
    exit 1
}

# ensure HODD_DIR exists
mkdir -p "${HODD_DIR}"
# save current dir on stack
pushd "${HODD_DIR}" >/dev/null
cd "${HODD_DIR}" || { exit 1; }

# check for image
HODD_ZIPFILE=$(basename ${HODD_URL})
if [ ! -f "${HODD_ZIPFILE}" ]; then
    # download image & unzip
    wget -nH -nd "${HODD_URL}"
    unzip -t "${HODD_ZIPFILE}"
    unzip "${HODD_ZIPFILE}"
fi

INDEX_FILE=$(find . -type f -name "index.html")
echo
echo "You can now open ${INDEX_FILE} in your browser."
echo

# return to current dir from stack
popd >/dev/null
