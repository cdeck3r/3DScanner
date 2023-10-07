#!/bin/bash
set -e

#
# Runs a python script to export the live camera image to a remote desktop
# The shell script previously stops the homie_camnode service
# to give the python script access to the camera.
#

# Params: all params will given as params to python script

# Exit codes
# 1 - if precond not satisfied
# 2 - if other things break

# this directory is the script directory
SCRIPT_DIR="$(
    cd "$(dirname "$0")" || exit
    pwd -P
)"
cd "$SCRIPT_DIR" || exit
# shellcheck disable=SC2034
SCRIPT_NAME=$0

# variables
USER="pi"
USER_HOME="/home/${USER}"
USER_ID=$(id -u "${USER}")
LOG_DIR="${USER_HOME}/log"

PY_INSTALL="python3"
PY_EXPORT_SCRIPT="${SCRIPT_DIR}/export_image.py"

#####################################################
# Include Helper functions
#####################################################

# shellcheck disable=SC1090
source "${SCRIPT_DIR}/funcs.sh"

# verfies the script runs as ${USER}
check_user() {
    local CURR_USER

    CURR_USER=$(id --user --name)
    if [ "${CURR_USER}" != "${USER}" ]; then
        return 1
    fi

    return 0
}

# check that script files exists 
check_script() {
    local script_file=$1

    [[ -f "${script_file}" ]] || {
        log_echo "ERROR" "Script not found: ${script_file}"
        return 1
    }
    return 0
}

# check tool exists 
check_tool() {
    local tool=$1

    command -v "${tool}" >/dev/null 2>&1 || { 
        log_echo "ERROR" "Tool not found: ${tool}" 
        return 1
    }
    return 0
}


#####################################################
# Main program
#####################################################

# basic checks
assert_on_raspi
assert_on_camnode

check_user || {
    log_echo "ERROR" "User mismatch. Script must run as user: ${USER}. Abort."
    exit 1
}

# just be sure
mkdir -p "${LOG_DIR}"

log_echo "INFO" "Prepare live camera image export"

# 1. Some checks first
check_tool "${PY_INSTALL}" || { exit 1; }
check_script "${PY_EXPORT_SCRIPT}" || { exit 1; }

# 2. Stop the camnode service.
log_echo "INFO" "Stop homie_camnode.service"
XDG_RUNTIME_DIR=/run/user/${USER_ID} systemctl --user stop homie_camnode.service || { log_echo "ERROR" "Error when stopping homie_camnode.service: $?"; echo "Abort"; exit 2; }

# 3. exec to python script
log_echo "INFO" "Start ${PY_EXPORT_SCRIPT} with params: $@"
exec "${PY_INSTALL}" "${PY_EXPORT_SCRIPT}" "$@"

exit 0
