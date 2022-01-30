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

    TRACKER=$(get_tracker "TRACKER_ETHERCALC")
    if [ -z "${TRACKER}" ]; then
        log_echo "ERROR" "Could not find my tracker from ini file: TRACKER_ETHERCALC"
        return 1
    fi

    log_echo "INFO" "Tracker ethercalc for URL ${TRACKER}"

    if [[ "${TRACKER}" != *"/_/"* ]]; then
        TRACKER_URL="$(dirname "${TRACKER}")/_/$(basename "${TRACKER}")"
        TRACKER="${TRACKER_URL}"
    fi

    TS="$(date '+%Y-%m-%d %H:%M:%S')"
    HOST_DATA="${TS},$(hostname --short),$(hostname --long),$(hostname --ip-address),$(hostname --all-ip-addresses),$(hostname --all-fqdns)"

    read -r CURL_EC_APPEND <<EOM
echo "$HOST_DATA" | \
curl -L -s -o /dev/null -w "%{response_code}" \
     --include \
     --request POST \
     --header "Content-Type: text/csv" \
     --data-binary @- '$TRACKER'
EOM

    #echo "Command: $CURL_EC_APPEND"
    CURL_RET="$(eval "${CURL_EC_APPEND}")"
    #echo "Return code: ${CURL_RET}"
    [[ ${CURL_RET} -eq 202 ]] || { log_echo "ERROR" "Could not publish to tracker. HTTP response code: ${CURL_RET}"; }

    return 0
}
