
#
# Contains the setup for the entire test run
#


# variables
TEST_LOG_DIR="/tmp/test_housekeeping"
TEST_LOG_FILE="${TEST_LOG_DIR}/housekeeping.log"
export TEST_LOG_DIR
export TEST_LOG_FILE
 
# array of function names to mask out from SUT
MOCKED_FUN=()


#
# mockup functions
#
# Convention: prefix function name by '_'
#
_check_user() {
    # always returns true
    return 0
}

_get_logfile() {
    # returns the log file for unit tests
    echo "${TEST_LOG_FILE}"
}

mock_function() {
    local fun=$1
    local mock=$2
    
    export -f ${mock}
    fake ${fun} ${mock}
    
    # add to MOCKED_FUN array 
    MOCKED_FUN+=("${fun}")
}

setup_suite() {
    # enforce bash variable controls during core tests
    # this way we know that people using this enforcement
    # in their own code can still rely on bash_unit
    #set -u
    # mockup
    mkdir -p "${TEST_LOG_DIR}"
    mock_function check_user _check_user
    mock_function get_logfile _get_logfile 
    
    # re-write SUT
    # the MOCKED_FUN array is filled by mock_function()
    for fun in "${MOCKED_FUN[@]}"
    do
        echo 's/(^'"${fun}"'\s?\(\))/_masked_out_\1/g;' 
    done | sed -E -f - "${SUT}" > "${_SUT}"
    chmod 700 "${_SUT}"
}

teardown_suite() {
    rm -rf "${TEST_LOG_DIR}"
    rm -rf "${_SUT}"
}