# shellcheck disable=SC2148

#
# Some common functions
#
# Author: cdecke3r
#

#
# logging on stdout
# Param #1: log level, e.g. INFO, WARN, ERROR
# Param #2: log message
log_echo() {
    LOG_LEVEL=$1
    LOG_MSG=$2
    TS=$(date '+%Y-%m-%d %H:%M:%S,%s')
    echo "$TS - $SCRIPT_NAME - $LOG_LEVEL - $LOG_MSG"
}

# no args
assert_on_raspi() {
    # check we are on Raspi
    MACHINE=$(uname -m)
    if [[ "$MACHINE" != arm* ]]; then
        log_echo "ERROR" "We are not on an arm plattform: ${MACHINE}"
        exit 1
    fi
}

# return true, if argument is substring in hostname
is_hostname() {
    local name=$1

    # no name provided, return false
    [[ -z "${name}" ]] && {
        log_echo "ERROR" "Argument empty in is_hostname()"
        return 1
    }

    # test for hostname
    command -v "hostname" >/dev/null || {
        log_echo "ERROR" "Could not find tool: hostname"
        return 1
    }
    hostname | grep -i "${name}" >/dev/null && return 0

    return 1
}

# no args
assert_on_centralnode() {
    is_hostname "centralnode" || {
        log_echo "ERROR" "Script must run on CENTRALNODE. Abort"
        exit 1
    }
}

# no args
assert_on_camnode() {
    is_hostname "camnode" || {
        log_echo "ERROR" "Script must run on CAMNODE. Abort"
        exit 1
    }
}

#
# assert docker
# we expect the script to execute within the docker container
assert_in_docker() {
    # Src: https://stackoverflow.com/a/20012536
    grep -Eq '/(lxc|docker)/[[:xdigit:]]{64}' /proc/1/cgroup || {
        log_echo "ERROR" "Please run this script in docker container"
        exit 1
    }
}
