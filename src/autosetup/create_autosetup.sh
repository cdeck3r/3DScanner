#!/bin/bash
set -e

#
# Create the autosetup_NODEYPE.zip file
# The archive contains
# - ssh keys
# - NODETYPE definition
# - autosetup.sh
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
AUTOSETUP="${SCRIPT_DIR}"/autosetup.sh
ALLKEYS_ZIP="${SCRIPT_DIR}"/allkeys.zip
TRACKER_INI="${SCRIPT_DIR}"/scanodis_tracker.ini
FORCE=$1

#####################################################
# Include Helper functions
#####################################################

#
# assert docker
# we expect the script to execute within the docker container
assert_in_docker() {
    # Src: https://stackoverflow.com/a/20012536
    grep -Eq '/(lxc|docker)/[[:xdigit:]]{64}' /proc/1/cgroup || {
        echo "ERROR: Please run this script in docker container"
        exit 1
    }
}


#####################################################
# Main program
#####################################################

assert_in_docker # only works in DEV system

# safety check
# do not delete / overwrite existing .zip files accidentially
if [ -f "${SCRIPT_DIR}/allkeys.zip" ] && [ "${FORCE}" != "-f" ]; then
    echo ".zip files found. Will not continue."
    echo "Use: ${SCRIPT_NAME} -f"
    exit 1
fi

# check for installed program
# Source: https://stackoverflow.com/a/677212
command -v "ssh-keygen" >/dev/null 2>&1 || {
    echo >&2 "I require ssh-keygen but it's not installed.  Abort."
    exit 1
}
command -v "zip" >/dev/null 2>&1 || {
    echo >&2 "I require zip but it's not installed.  Abort."
    exit 1
}
command -v "curl" >/dev/null 2>&1 || {
    echo >&2 "I require curl but it's not installed.  Abort."
    exit 1
}

# we need the basic autosetup.sh script
if [ ! -f "${AUTOSETUP}" ]; then
    echo "File not found: ${AUTOSETUP}"
    exit 1
fi

# generate ssh keys
echo "Create auth keys ..."
for KEYFILE in "camnode" "centralnode"; do
    ssh-keygen -q -t rsa -f "${SCRIPT_DIR}"/"${KEYFILE}" -N "" -C "${KEYFILE} ssh key"
    mv "${SCRIPT_DIR}"/"${KEYFILE}" "${SCRIPT_DIR}"/"${KEYFILE}".priv
done

#
# create TRACKER_INI for the default tracker: ethercalc
#
echo "Create ${TRACKER_INI} ... (this may take a while)"
EC_HEADER="localtime,hostname --short,hostname --long,hostname --ip-address,hostname --all-ip-addresses,hostname --all-fqdns"
read -r CURL_EC_CREATE <<EOM
echo "${EC_HEADER}" | \
curl -L -s -w "\\nresponse_code:%{response_code}" --insecure \
     --include \
     --request POST \
     --header "Content-Type: text/csv" \
     --data-binary @- 'https://www.ethercalc.net/_'
EOM
CURL_RET="$(eval "${CURL_EC_CREATE}")"
CURL_RET_LOCATION="$(echo -e "${CURL_RET}" | grep -Fi location | cut -d'/' -f3 | tr -d '\r\n')"
CURL_RET_RESPONSE="$(echo -e "${CURL_RET}" | grep -Fi response_code | cut -d':' -f2 | tr -d '\r\n')"
# debug
#echo "Command: $CURL_EC_CREATE"
#echo "LOCATION: ${CURL_RET_LOCATION}"
#echo "RESPONSE_CODE: ${CURL_RET_RESPONSE}"
# test, if creation was successful
[[ ${CURL_RET_RESPONSE} -eq 201 ]] || {
    echo "ERROR: Could not create tracker site. HTTP response code: ${CURL_RET_RESPONSE}"
    exit 2
}
TRACKER_SITE="https://ethercalc.net/${CURL_RET_LOCATION}"
# write tracker ini
{
    echo "# SCANODIS - Scanner Node Discovery Tracker file"
    echo "# "
    echo "# This file contains tracker URLs."
    echo "# See src/scanodis for more information."
    echo "# "
    echo "TRACKER_ETHERCALC=\"${TRACKER_SITE}\""
} >"${TRACKER_INI}"
# test, if tracker is active
CURL_RET="$(curl -L -s -o /dev/null -w "%{response_code}" "${TRACKER_SITE}")"
[[ ${CURL_RET} -eq 200 ]] || {
    echo "ERROR: Could not retrieve tracker site: ${TRACKER_SITE}"
    echo "HTTP response code: ${CURL_RET}"
    exit 2
}
#
# /tracker done
#

# package
for NODETYPE in "CAMNODE" "CENTRALNODE"; do
    # NODETYPE definition
    echo "$NODETYPE" >"${SCRIPT_DIR}"/NODETYPE
    chmod 644 "${SCRIPT_DIR}"/NODETYPE

    #zip autosetup_NODEYPE.zip
    # autosetup.sh
    # NODETYPE
    # keyfile

    KEYFILE=$(echo ${NODETYPE} | tr '[:upper:]' '[:lower:]')
    SSH_KEYFILE_PUB=${KEYFILE}.pub
    SSH_KEYFILE_PRIV=""
    TRACKER_INI_FILE=""

    if [ "${NODETYPE}" = "CENTRALNODE" ]; then
        SSH_KEYFILE_PRIV=camnode.priv # add camnode's private key for centralnode
        TRACKER_INI_FILE="${TRACKER_INI}"
    fi

    # zip "SSH_KEYFILE" NODETYPE "${AUTOSETUP}"
    AUTOSETUP_ZIP=$(echo autosetup_${NODETYPE}.zip | tr '[:upper:]' '[:lower:]')
    rm -rf "${SCRIPT_DIR:?}/${AUTOSETUP_ZIP}"
    echo "Create $AUTOSETUP_ZIP..."
    zip -j -q "${AUTOSETUP_ZIP}" "${SSH_KEYFILE_PUB}" "${SSH_KEYFILE_PRIV}" "${SCRIPT_DIR}"/NODETYPE "${AUTOSETUP}" "${TRACKER_INI_FILE}"
done

# package all keys in a separate zip
rm -rf "${ALLKEYS_ZIP}"
echo "Create $(basename "${ALLKEYS_ZIP}")..."
for KEYFILE in "camnode" "centralnode"; do
    SSH_KEYFILE_PUB=${KEYFILE}.pub
    SSH_KEYFILE_PRIV=${KEYFILE}.priv
    zip -j -q "${ALLKEYS_ZIP}" "${SSH_KEYFILE_PUB}" "${SSH_KEYFILE_PRIV}" "${TRACKER_INI}"
done

# cleanup
rm -rf "${SCRIPT_DIR}"/NODETYPE
for KEYFILE in "camnode" "centralnode"; do
    rm -rf "${SCRIPT_DIR:?}"/"${KEYFILE}"*
done
rm -rf "${TRACKER_INI}"

exit 0
