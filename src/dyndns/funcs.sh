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
detect_on_platform() {
    local machine
    # check we are on Raspi
    machine=$(uname -m)
    echo "${machine}"
}

# no args
assert_on_raspi() {
    # check we are on Raspi
    MACHINE=$(detect_on_platform)
    if [[ "$MACHINE" != arm* ]]; then
        log_echo "ERROR" "We are not on an arm plattform: ${MACHINE}"
        exit 1
    fi
}

# no args
assert_on_pc() {
    # check we are on Raspi
    MACHINE=$(detect_on_platform)
    if [[ "$MACHINE" != x86* ]]; then
        log_echo "ERROR" "We are not on a X86 plattform: ${MACHINE}"
        exit 1
    fi
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
