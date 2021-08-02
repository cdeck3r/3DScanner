#!/bin/bash

#
# We test for different invalid input param format
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

#####################################################
# Unit tests
#####################################################

# shellcheck disable=SC1090
source "${SCRIPT_DIR}/setup_suite.sh"

test_no_params() {
    assert_fail "${_SUT}" "Script should exit 1, if no params were given"
}

test_only_one_param() {
    assert_fail "${_SUT} data_dir" "Script should exit 1, if only one param was given"
}

test_two_text_params() {
    assert_fail "${_SUT} data_dir low_watermark" "Script should exit 1, if two text params were given"
}

test_two_params_text_negint() {
    assert_fail "${_SUT} data_dir -123" "Script should exit 1, if low watermark is a negative integer"
}

test_two_params_text_float() {
    assert_fail "${_SUT} data_dir 1.23" "Script should exit 1, if low watermark is a float"
}

test_two_params_text_negfloat() {
    assert_fail "${_SUT} data_dir -1.23" "Script should exit 1, if low watermark is a negative float"
}

test_three_text_params() {
    assert_fail "${_SUT} data_dir low_watermark high_watermark" "Script should exit 1, if all params are text"
}

test_three_params_text_int() {
    assert_fail "${_SUT} data_dir low_watermark 123" "Script should exit 1, if one of the watermark params ist not an integer"
}

test_three_params_text_negint() {
    assert_fail "${_SUT} data_dir low_watermark -123" "Script should exit 1, if one of the watermark params ist not an integer"
}

test_three_params_text_float() {
    assert_fail "${_SUT} data_dir low_watermark 1.23" "Script should exit 1, if one of the watermark params ist not an integer"
}

test_three_params_text_negfloat() {
    assert_fail "${_SUT} data_dir low_watermark -1.23" "Script should exit 1, if one of the watermark params ist not an integer"
}

test_three_params_int_text() {
    assert_fail "${_SUT} data_dir 123 text" "Script should exit 1, if one of the watermark params ist not an integer"
}

test_three_params_negint_text() {
    assert_fail "${_SUT} data_dir -123 text" "Script should exit 1, if one of the watermark params ist not an integer"
}

test_three_params_float_text() {
    assert_fail "${_SUT} data_dir 1.23 text" "Script should exit 1, if one of the watermark params ist not an integer"
}

test_three_params_negfloat_text() {
    assert_fail "${_SUT} data_dir -1.23 text" "Script should exit 1, if one of the watermark params ist not an integer"
}
