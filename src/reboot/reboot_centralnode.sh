#!/bin/bash
set -e

#
# CENTRALNODE reboot
# Runs jobs after the reboot
#

# Params: none

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
LOG_DIR="${USER_HOME}/log"
SCANODIS_SH="${USER_HOME}/scanodis/scanodis.sh"
RESTART_HOMIE_CAMNODE_SH="${USER_HOME}/script-server/scripts/restart_homie_camnode.sh"
VARS="${USER_HOME}/script-server/scripts/common_vars.conf"

#####################################################
# Include Helper functions
#####################################################

# shellcheck disable=SC1090
source "${SCRIPT_DIR}/funcs.sh"
# shellcheck disable=SC1090
source "${VARS}"

# verfies the script runs as ${USER}
check_user() {
    local CURR_USER

    CURR_USER=$(id --user --name)
    if [ "${CURR_USER}" != "${USER}" ]; then
        return 1
    fi

    return 0
}

# check that script files exists and
# is executable
check_script() {
    local script_file=$1

    [[ -f "${script_file}" ]] || {
        log_echo "ERROR" "Script not found: ${script_file}"
        return 1
    }
    [[ -x "${script_file}" ]] || {
        log_echo "ERROR" "Script not executable: ${script_file}"
        return 1
    }

    return 0
}

check_mqtt() {
    # min req.
    [[ -n "${MQTT_BROKER}" ]] || {
        log_echo "ERROR" "Variable MQTT_BROKER not set"
        return 1
    }

    # check for required tools avail from shell
    TOOLS=('mosquitto_sub' 'mosquitto_pub')
    for t in "${TOOLS[@]}"; do
        # check for installed program
        # Source: https://stackoverflow.com/a/677212
        command -v "${t}" >/dev/null 2>&1 || {
            log_echo "ERROR" "Tool not found: $t"
            return 1
        }
    done

    return 0
}

#####################################################
# Main program
#####################################################

# basic checks
assert_on_raspi
assert_on_centralnode

check_user || {
    log_echo "ERROR" "User mismatch. Script must run as user: ${USER}. Abort."
    exit 1
}

# just be sure
mkdir -p "${LOG_DIR}"

log_echo "INFO" "Start jobs after reboot"

# 1. After reboot run scanodis twice to get a fresh `nodelist.log`.
check_script "${SCANODIS_SH}" || { exit 1; }
log_echo "INFO" "Run scanodis twice"
"${SCANODIS_SH}" || { log_echo "WARN" "scanodis returned an error. Check log."; }
"${SCANODIS_SH}" || { log_echo "WARN" "scanodis returned an error. Check log."; }

# 2. Optional: Clear up all retained messages from mosquitto
# Source: https://stackoverflow.com/a/69067244
check_mqtt && {
    mosquitto_sub -h "${MQTT_BROKER}" -t "#" -v --retained-only | while read -r line; do mosquitto_pub -h "${MQTT_BROKER}" -t "${line%% *}" -r -n; done || { log_echo "WARN" "Error deleting retained messages from MQTT broker. Ignored."; }
}

# 3. Finally, restart the camnode services on all camnodes.
check_script "${RESTART_HOMIE_CAMNODE_SH}" || { exit 1; }
log_echo "INFO" "Restart the camnode services on all camnodes"
"${RESTART_HOMIE_CAMNODE_SH}" || { echo "Ignore error: $?"; }

exit 0
