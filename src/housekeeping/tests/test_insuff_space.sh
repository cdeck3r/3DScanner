#!/bin/bash

#
# In all test cases, we assume free space below low watermark
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
TEST_FREE=0

#####################################################
# Unit tests
#####################################################

source "${SCRIPT_DIR}/setup_suite.sh"

_logfile_start() {
    head -n1 "${TEST_LOG_FILE}" | grep "Start housekeeping for directory (low/high): ${TEST_DATA_DIR}"
}
_logfile_delete_empty_dirs() {
    grep "Delete all empty directories in directory: ${TEST_DATA_DIR}" "${TEST_LOG_FILE}"
}

_create_test_data() {
    local _TEST_FILE=$1
    local _TEST_FILE_SIZE=$2
    head -c "${_TEST_FILE_SIZE}" < /dev/random > "${_TEST_FILE}"
}

_files_in_test_data_dir() {
    # inspired: https://unix.stackexchange.com/a/202276
    #echo $(ls -1qA "${TEST_DATA_DIR}" | wc -l)
    echo $(find "${TEST_DATA_DIR}" -type f | wc -l)
}

_files_in_test_data_dir_equals() {
    local cnt=$1
    local file_cnt
        
    file_cnt="$(_files_in_test_data_dir)"
    ((file_cnt == cnt)) && { return 0; }
    return 1
}

test_empty_data_dir() {
    assert "_files_in_test_data_dir_equals 0"
    # we are below 
    LOW_WATERMARK=$((TEST_FREE+1024))
    assert "${_SUT} ${TEST_DATA_DIR} ${LOW_WATERMARK}"
    assert _logfile_start
    assert "grep 'Insufficient space' ${TEST_LOG_FILE}"
    assert "grep 'Start deleting files from directory:' ${TEST_LOG_FILE}"
    assert "grep 'Deleted files: 0' ${TEST_LOG_FILE}"
    assert _logfile_delete_empty_dirs
}

test_delete_one_file_dir_empty() {
    # create data in TEST_DATA_DIR
    _create_test_data "${TEST_DATA_DIR}/singlefile.dat" "1M"
    assert "_files_in_test_data_dir_equals 1"
    # we are below 
    LOW_WATERMARK="${TEST_FREE}"
    assert "${_SUT} ${TEST_DATA_DIR} ${LOW_WATERMARK}"
    assert _logfile_start
    assert "grep 'Insufficient space' ${TEST_LOG_FILE}"
    assert "grep 'Start deleting files from directory:' ${TEST_LOG_FILE}"

    assert "grep 'Deleted files: 1' ${TEST_LOG_FILE}"
    assert "_files_in_test_data_dir_equals 0"
    assert _logfile_delete_empty_dirs
}


test_delete_files_when_no_high_watermark_is_given() {
    # create data in TEST_DATA_DIR
    for i in {1..5}
    do
        _create_test_data "${TEST_DATA_DIR}/testfile_$i.dat" "1M"
    done
    assert "_files_in_test_data_dir_equals 5"
    # we are below 
    LOW_WATERMARK=$((TEST_FREE-1024)) # dec by 1M 
    assert "${_SUT} ${TEST_DATA_DIR} ${LOW_WATERMARK}"
    assert _logfile_start
    assert "grep 'Insufficient space' ${TEST_LOG_FILE}"
    assert "grep 'Start deleting files from directory:' ${TEST_LOG_FILE}"

    assert "grep 'Deleted files: 5' ${TEST_LOG_FILE}"
    assert "_files_in_test_data_dir_equals 0"
    assert _logfile_delete_empty_dirs
}

test_delete_files_when_high_watermark_is_less_than_low_watermark() {
    # create data in TEST_DATA_DIR
    for i in {1..5}
    do
        _create_test_data "${TEST_DATA_DIR}/testfile_$i.dat" "1M"
    done
    assert "_files_in_test_data_dir_equals 5"
    # we are below 
    LOW_WATERMARK=$((TEST_FREE-1*1024+100)) # dec by 1M 
    HIG_WATERMARK=$((TEST_FREE-5*1024)) # dec by 5M 
    assert "${_SUT} ${TEST_DATA_DIR} ${LOW_WATERMARK} ${HIG_WATERMARK}"
    assert _logfile_start
    assert "grep 'Insufficient space' ${TEST_LOG_FILE}"
    assert "grep 'Start deleting files from directory:' ${TEST_LOG_FILE}"
    assert "grep 'Deleted files: 1' ${TEST_LOG_FILE}"
    assert "_files_in_test_data_dir_equals 4"
    assert _logfile_delete_empty_dirs
}

test_delete_one_file_leave_one() {
    # create data in TEST_DATA_DIR
    _create_test_data "${TEST_DATA_DIR}/file_one.dat" "1M"
    _create_test_data "${TEST_DATA_DIR}/file_two.dat" "1M"
    assert "_files_in_test_data_dir_equals 2"
    # we are in between
    LOW_WATERMARK=$((TEST_FREE-2*1024+100)) # dec by 2M and add 100k
    HIGH_WATERMARK=$((TEST_FREE-1024-100))
    assert "${_SUT} ${TEST_DATA_DIR} ${LOW_WATERMARK} ${HIGH_WATERMARK}"
    assert _logfile_start
    assert "grep 'Insufficient space' ${TEST_LOG_FILE}"
    assert "grep 'Start deleting files from directory:' ${TEST_LOG_FILE}"
    assert "grep 'Deleted files: 1' ${TEST_LOG_FILE}"
    assert "_files_in_test_data_dir_equals 1"
    assert_fail "ls ${TEST_DATA_DIR}/file_one.dat"   
    assert "ls ${TEST_DATA_DIR}/file_two.dat"   
    assert _logfile_delete_empty_dirs
}

test_delete_two_files_leave_two() {
    # create data in TEST_DATA_DIR
    _create_test_data "${TEST_DATA_DIR}/file_one.dat" "1M"
    _create_test_data "${TEST_DATA_DIR}/file_two.dat" "1M"
    _create_test_data "${TEST_DATA_DIR}/file_three.dat" "1M"
    _create_test_data "${TEST_DATA_DIR}/file_four.dat" "1M"
    assert "_files_in_test_data_dir_equals 4"
    # we are in between
    LOW_WATERMARK=$((TEST_FREE-4*1024+100)) # dec by 4M and add 100k
    HIGH_WATERMARK=$((TEST_FREE-2*1024-100))
    assert "${_SUT} ${TEST_DATA_DIR} ${LOW_WATERMARK} ${HIGH_WATERMARK}"
    assert _logfile_start
    assert "grep 'Insufficient space' ${TEST_LOG_FILE}"
    assert "grep 'Start deleting files from directory:' ${TEST_LOG_FILE}"
    assert "grep 'Deleted files: 2' ${TEST_LOG_FILE}"
    assert "_files_in_test_data_dir_equals 2"
    assert_fail "ls ${TEST_DATA_DIR}/file_one.dat"
    assert_fail "ls ${TEST_DATA_DIR}/file_two.dat"   
    assert "ls ${TEST_DATA_DIR}/file_three.dat"   
    assert "ls ${TEST_DATA_DIR}/file_four.dat"   
    assert _logfile_delete_empty_dirs
}


test_delete_files_in_directory_structure() {
    # create data in TEST_DATA_DIR
    mkdir -p "${TEST_DATA_DIR}/testdir1"
    mkdir -p "${TEST_DATA_DIR}/testdir2"
    _create_test_data "${TEST_DATA_DIR}/testdir1/file_one.dat" "1M"
    _create_test_data "${TEST_DATA_DIR}/testdir2/file_two.dat" "1M"
    # 
    mkdir -p "${TEST_DATA_DIR}/emptytestdir"
    assert "_files_in_test_data_dir_equals 2"
    assert "ls ${TEST_DATA_DIR}/emptytestdir"
    
    # we are in between
    LOW_WATERMARK=$((TEST_FREE-2*1024+100)) # dec by 2M and add 100k
    HIGH_WATERMARK=$((TEST_FREE-1024-100))
    assert "${_SUT} ${TEST_DATA_DIR} ${LOW_WATERMARK} ${HIGH_WATERMARK}"
    assert _logfile_start
    assert "grep 'Insufficient space' ${TEST_LOG_FILE}"
    assert "grep 'Start deleting files from directory:' ${TEST_LOG_FILE}"
    assert "grep 'Deleted files: 1' ${TEST_LOG_FILE}"
    assert "_files_in_test_data_dir_equals 1"
    assert _logfile_delete_empty_dirs
    assert_fail "ls ${TEST_DATA_DIR}/emptytestdir" "Directory shall be removed"
}



setup() {
    mkdir -p "${TEST_DATA_DIR}"
    mkdir -p "${TEST_LOG_DIR}"
    
    PARTITION="/"
    TEST_FREE=$(df --output=avail -k "${PARTITION}" | tail -n1 | xargs)
}
teardown() {
    rm -rf "${TEST_DATA_DIR}"
    rm -rf "${TEST_LOG_DIR}"
}
