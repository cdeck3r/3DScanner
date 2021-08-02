#!/bin/bash
set -e

#
# Installs the free space management and logrotation as cronjobs
#
# Author: cdeck3r
#

# CLI Params:
# directory, where to delete files from
# low watermark [unit: KB]
# high watermark [unit: KB]
DATA_DIR=$1
LOW_MARK=$2
HIGH_MARK=$3

[[ -z "${LOW_MARK}" ]] && { LOW_MARK=$((1 * 1024 * 1024)); }   # 1GB default
[[ -z "${HIGH_MARK}" ]] && { HIGH_MARK=$((2 * 1024 * 1024)); } # 2GB default

# Exit codes
# 1 - if precond not satisfied
# 2 - if install routing breaks

# this directory is the script directory
SCRIPT_DIR="$(
    cd "$(dirname "$0")" || exit
    pwd -P
)"
cd "$SCRIPT_DIR" || exit
# shellcheck disable=SC2034
SCRIPT_NAME=$0

# variables
USER=pi
USER_HOME="/home/${USER}"
PARTITION="/"                                                   # partition to check for free space
TOTAL=$(df --output=size -k "${PARTITION}" | tail -n 1 | xargs) # total capacity

# logrotate
LOG_DIR="${USER_HOME}/log"
LOGROTATE_CONF="${SCRIPT_DIR}/logrotate.conf"
LOGROTATE_STATE="${LOG_DIR}/logrotate_housekeeping.state"
LOGROTATE_LOG="${LOG_DIR}/logrotate_housekeeping.log"

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

check_params() {
    # system must have more total capacity than low watermark
    ((TOTAL > LOW_MARK)) || {
        log_echo "ERROR" "Low watermark must be smaller than disk size. Abort."
        return 1
    }
    [[ -z "${DATA_DIR}" ]] && {
        log_echo "ERROR" "Housekeeping directory not provided. Abort."
        return 1
    }
    [[ -d "${DATA_DIR}" ]] || {
        log_echo "ERROR" "Housekeeping directory does not exist: ${DATA_DIR}. Abort."
        return 1
    }
    return 0
}

make_scripts_executable() {
    chmod -R 744 "${SCRIPT_DIR}"/*.sh
}

#
# Expands paths given as "~/<path>"
#
# Src: https://stackoverflow.com/a/29310477
#
expandPath() {
    local path
    local -a pathElements resultPathElements
    IFS=':' read -r -a pathElements <<<"$1"
    : "${pathElements[@]}"
    for path in "${pathElements[@]}"; do
        : "$path"
        case $path in
        "~+"/*)
            path=$PWD/${path#"~+/"}
            ;;
        "~-"/*)
            path=$OLDPWD/${path#"~-/"}
            ;;
        "~"/*)
            path=$HOME/${path#"~/"}
            ;;
        "~"*)
            username=${path%%/*}
            username=${username#"~"}
            IFS=: read -r _ _ _ _ _ homedir _ < <(getent passwd "$username")
            if [[ $path = */* ]]; then
                path=${homedir}/${path#*/}
            else
                path=$homedir
            fi
            ;;
        esac
        resultPathElements+=("$path")
    done
    local result
    printf -v result '%s:' "${resultPathElements[@]}"
    printf '%s\n' "${result%:}"
}

#####################################################
# Main program
#####################################################

check_user || {
    log_echo "ERROR" "User mismatch. Script must run as user: ${USER}. Abort."
    exit 1
}
make_scripts_executable || {
    log_echo "ERROR" "Scripts are not executable. Abort."
    exit 1
}
check_params || { exit 1; }

# remove all housekeeping jobs from crontab
crontab -l | grep -v 'housekeeping' | crontab - || { echo "Ignore error: $?"; }

# install housekeeping
if [ -f "${SCRIPT_DIR}/housekeeping.sh" ]; then
    (
        crontab -l
        echo "0 3 * * * ${SCRIPT_DIR}/housekeeping.sh ${DATA_DIR} ${LOW_MARK} ${HIGH_MARK} >/dev/null 2>&1"
    ) | sort | uniq | crontab - || {
        echo "Error adding cronjob. Code: $?"
        exit 2
    }
else
    echo "File does not exist: ${SCRIPT_DIR}/housekeeping.sh"
    echo "Could not install housekeeping cronjob"
    exit 2
fi

# housekeeping for temporary image directory
# created by the scanner apparatus device
#
# We retrieve the directory from homie_apparatus.yml, if it exists.
# If the yml file does not exist, we will do nothing.
#
[[ -f "${USER_HOME}/homie-apparatus/homie_apparatus.yml" ]] && {
    # extract temporary image path, expand it
    IMG_TMP_DIR=$(grep IMG_TMP_DIR "${USER_HOME}/homie-apparatus/homie_apparatus.yml" | cut -d$'\'' -f2)
    IMG_TMP_DIR_FULLPATH=$(expandPath "${IMG_TMP_DIR}")

    # create temporary image directory and install cronjob
    if (mkdir -p "${IMG_TMP_DIR_FULLPATH}"); then
        (
            crontab -l
            echo "30 3 * * * ${SCRIPT_DIR}/housekeeping.sh ${IMG_TMP_DIR_FULLPATH} ${TOTAL} >/dev/null 2>&1"
        ) | sort | uniq | crontab - || {
            echo "Error adding cronjob. Code: $?"
            exit 2
        }
    fi
}

# create log directory
mkdir -p "${LOG_DIR}"

# install daily logrotate cronjob - run each night at 2am
if [ -f "${LOGROTATE_CONF}" ]; then
    (
        crontab -l
        echo "30 2 * * * /usr/sbin/logrotate -s ${LOGROTATE_STATE} -l ${LOGROTATE_LOG} ${LOGROTATE_CONF} >/dev/null 2>&1"
    ) | sort | uniq | crontab - || {
        echo "Error adding cronjob. Code: $?"
        exit 2
    }
else
    echo "File does not exist: ${LOGROTATE_CONF}"
    echo "Could not install logrotate cronjob"
    exit 2
fi

exit 0
