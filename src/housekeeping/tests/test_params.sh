#!/bin/bash

#
# In all test cases, we assume correct params format.
# We test for valid param ranges
#

# this directory is the script directory
SCRIPT_DIR="$(
    cd "$(dirname "$0")" || exit
    pwd -P
)"
cd "$SCRIPT_DIR" || exit
# shellcheck disable=SC2034
SCRIPT_NAME=$0

# variables
SUT="${SCRIPT_DIR}/../housekeeping.sh"
_SUT="$(dirname "${SUT}")/_$(basename "${SUT}")"
TEST_DATA_DIR="/tmp/test_data_dir"

#####################################################
# Unit tests
#####################################################

source "${SCRIPT_DIR}/setup_suite.sh"

_logfile_start() {
    head -n1 "${TEST_LOG_FILE}" | grep "Start housekeeping for directory (low/high)"
}

test_invalid_data_dir() {
    local INVALID_TEST_DATA_DIR
    
    INVALID_TEST_DATA_DIR="invalid_${TEST_DATA_DIR}"
    assert_status_code 2 "${_SUT} ${INVALID_TEST_DATA_DIR} 123 456" 
}

test_low_watermark_gt_total() {
    local _LOW_WATERMARK=99999999999999999
    assert_status_code 2 "${_SUT} ${TEST_DATA_DIR} ${_LOW_WATERMARK} 456" 
}

test_high_watermark_not_provided() {
    assert "${_SUT} ${TEST_DATA_DIR} 123" 
    assert _logfile_start
    assert "grep 'High watermark not specified. Will delete the entire directory' ${TEST_LOG_FILE}"
}

test_high_watermark_gt_total() {
    local _HIGH_WATERMARK=99999999999999999
    assert "${_SUT} ${TEST_DATA_DIR} 123 ${_HIGH_WATERMARK}" 
    assert _logfile_start
    assert "grep 'High watermark is greater than total disk space' ${TEST_LOG_FILE}"
}

test_sufficient_space() {
    PARTITION="/"
    FREE=$(df --output=avail -k "${PARTITION}" | tail -n1 | xargs)
    LOW_WATERMARK=$((FREE-1024))
    assert "${_SUT} ${TEST_DATA_DIR} ${LOW_WATERMARK}"
    assert _logfile_start
    assert "grep 'Sufficient free space avail:' ${TEST_LOG_FILE}"
}


setup() {
    mkdir -p "${TEST_DATA_DIR}"
    mkdir -p "${TEST_LOG_DIR}"
}
teardown() {
    rm -rf "${TEST_DATA_DIR}"
    rm -rf "${TEST_LOG_DIR}"
}
