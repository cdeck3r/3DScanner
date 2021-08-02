#!/bin/bash

#
# Starts the bash_unit tests
# https://github.com/pgrange/bash_unit
#
# 1. test for bash_unit
# 1a. in case, test fails: download bash_unit
# 2. start bash_unit tests
#
# Author: cdeck3r
#

# Params: none

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

#####################################################
# Include Helper functions
#####################################################

# shellcheck disable=SC1090
source "${SCRIPT_DIR}/../funcs.sh"

# src: https://github.com/pgrange/bash_unit#other-installation
install_bash_unit() {
    bash <(curl -s https://raw.githubusercontent.com/pgrange/bash_unit/master/install.sh)
}

#####################################################
# Main program
#####################################################

[[ -f "./bash_unit" ]] || {
    log_echo "WARN" "bash_unit test framework not found."
    install_bash_unit || {
        log_echo "ERROR" "Could not install bash_unit test framework. Abort."
        exit 2
    }
}

log_echo "INFO" "Run unit tests in directory: ${SCRIPT_DIR}"
# start
./bash_unit test_cli.sh
./bash_unit test_params.sh
./bash_unit test_insuff_space.sh