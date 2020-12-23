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
    local TRACKER
    local TMPFILE
    
    TMPFILE=$(mktemp)

    # check for installed program
    # Source: https://stackoverflow.com/a/677212
    command -v "avahi-browse" >/dev/null 2>&1 || { log_echo "ERROR" "I require avahi-browse, but it's not installed.  Abort."; return 1; }

    # run avahi-browse
    # avahi-browse -atr | grep hostname | grep camnode | | cut -d' ' -f6 | cut -d'[' -f2 | cut -d']' -f1 | uniq > "${TMPFILE}" 
    # avahi-resolve -4 -n ${h} 
    
    return 0
}
