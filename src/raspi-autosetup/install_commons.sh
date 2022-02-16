#!/bin/bash
set -e

#
# Install common software packages
#
# Author: cdeck3r
#

# Params: none

# Exit codes
# >0 if script breaks

# Variables
CONF="/etc/systemd/system.conf"

#####################################################
# Include Helper functions
#####################################################

# returns true, if watchdog is configured in ${CONF}
is_wd_configured() {
    grep -q "^RuntimeWatchdogSec=" "${CONF}" && return 0
    return 1
}

# returns true, if watchdog is active
is_wd_active() {
    journalctl --no-pager -k | grep -q "Set hardware watchdog to" && return 0
    return 1
}

#####################################################
# Main program
#####################################################

# Install hardware watchdog
# 1. check for configfile and watchdog running
# 2. if not, modify conf file
# 3. reload systemctl daemons and reboot system
{ [[ -f "${CONF}" ]] && ! is_wd_configured && ! is_wd_active; } && {
    echo "WARN: Hardware watchdog is NOT active. Will setup watchdog now."

    # RuntimeWatchdogSec=10
    grep -q "^#RuntimeWatchdogSec=" "${CONF}" && sed "s/^#RuntimeWatchdogSec=.*/RuntimeWatchdogSec=10/" -i "${CONF}"
    { grep -q "^RuntimeWatchdogSec=" "${CONF}" && sed "s/^RuntimeWatchdogSec=.*/RuntimeWatchdogSec=10/" -i "${CONF}"; } || echo 'RuntimeWatchdogSec=10' >>"${CONF}"
    # ShutdownWatchdogSec=10min
    grep -q "^#ShutdownWatchdogSec=" "${CONF}" && sed "s/^#ShutdownWatchdogSec=.*/ShutdownWatchdogSec=10min/" -i "${CONF}"
    { grep -q "^ShutdownWatchdogSec=" "${CONF}" && sed "s/^ShutdownWatchdogSec=.*/ShutdownWatchdogSec=10min/" -i "${CONF}"; } || echo 'ShutdownWatchdogSec=10min' >>"${CONF}"

    echo "INFO: System reloads daemons and reboots to make watchdog effective."
    systemctl daemon-reload || { echo "Error ignored $?"; } # otherwise we exit and repeat
    shutdown -r now
}

# ignore wrong date
apt-get update -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false

# cleanup
apt-get clean && rm -rf /var/lib/apt/lists/*
