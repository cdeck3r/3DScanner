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
    local TS

    TRACKER=$(get_tracker "TRACKER_NWEB")
    if [ -z "${TRACKER}" ]; then
        echo "Could not found my tracker from ini file: NWEB"
        return 1
    fi

    echo "INFO: Tracker nweb for URL ${TRACKER}"

    wget "${TRACKER}/index.html?ip=$(hostname -I)" || { echo "Error ignored: $?"; }

    return 0
}
