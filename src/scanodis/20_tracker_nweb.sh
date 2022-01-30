# shellcheck disable=SC2148

#
# scanodis (scanner node discovery) tracker
# it publishes node specific data to a tracker
#

#####################################################
# Include Helper functions
#####################################################

#####################################################
# Main program
#####################################################

publish_to_tracker() {
    local TRACKER

    TRACKER=$(get_tracker "TRACKER_NWEB")
    if [ -z "${TRACKER}" ]; then
        log_echo "ERROR" "Could not find my tracker from ini file: NWEB"
        return 1
    fi

    log_echo "INFO" "Tracker nweb for URL ${TRACKER}"

    wget --tries=2 --timeout=10 "${TRACKER}/index.html?name=3Dscanner&ip=$(hostname -I)" || { log_echo "ERROR" "wget did not complete successfully. Return code: $?"; }

    return 0
}
