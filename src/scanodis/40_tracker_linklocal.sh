# shellcheck disable=SC2148

#
# scanodis (scanner node discovery) tracker
# it discovers scanner nodes using mDNS
#

#####################################################
# Include Helper functions
#####################################################

#####################################################
# Main program
#####################################################

publish_to_tracker() {
    local TMPFILE
    local NODELIST

    TMPFILE=$(mktemp)
    NODELIST="${LOG_DIR}/nodelist.log"

    # check for installed program
    # Source: https://stackoverflow.com/a/677212
    command -v "avahi-browse" >/dev/null 2>&1 || {
        log_echo "ERROR" "I require avahi-browse, but it's not installed.  Abort."
        return 1
    }
    command -v "avahi-resolve" >/dev/null 2>&1 || {
        log_echo "ERROR" "I require avahi-resolve, but it's not installed.  Abort."
        return 1
    }

    log_echo "INFO" "Tracker link-local"

    # run avahi-browse
    log_echo "INFO" "Run avahi-browse"
    avahi-browse -atr | grep hostname | grep camnode | tr '[:space:]' '\n' | grep local | sort | uniq | sed 's/\[\(.\+\)\]/\1/g' >"${TMPFILE}"
    # resolve all found hosts and log them
    log_echo "INFO" "Run avahi-resolve"
    while IFS="" read -r h || [ -n "$h" ]; do
        avahi-resolve -4 -n "${h}" >>"${NODELIST}"
    done <"${TMPFILE}"

    # cleanup
    rm -rf "${TMPFILE}"

    return 0
}
