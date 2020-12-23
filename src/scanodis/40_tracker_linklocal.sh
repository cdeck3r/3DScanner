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

    # check for installed program
    # Source: https://stackoverflow.com/a/677212
    command -v "avahi-browse" >/dev/null 2>&1 || { log_echo "ERROR" "I require avahi-browse, but it's not installed.  Abort."; return 1; }

    # run avahi-browse
    # avahi-browse -atp | grep camnode | grep -i ipv4 | grep -i ssh 
    
    return 0
}
