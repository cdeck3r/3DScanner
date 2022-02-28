#!/bin/bash

#
# Remotely runs a shell command on a list of camnodes
#
# Author: cdeck3r
#

# Params: none

# Exit codes
# >0 if script breaks

# this directory is the script directory
SCRIPT_DIR="$(
    cd "$(dirname "$0")" || exit
    pwd -P
)"
cd "$SCRIPT_DIR" || exit
# shellcheck disable=SC2034
SCRIPT_NAME=$0

# variables
REMOTE_SHELL="${SCRIPT_DIR}/remote_bash.sh"
REMOTE_CMD_ARRAY=()

#
# Various commands
#
# arpscan.txt
IP_LIST=$2

#####################################################
# Include Helper functions
#####################################################

usage() {
    echo "Usage: ${SCRIPT_NAME} [-abcdefghijk] <IP_LIST>"
}


while getopts "abcdefghijk" opt; do
  case "${opt}" in
    a)
        # Find under-voltage messages
        REMOTE_CMD="hostname && journalctl --no-pager | grep -i voltage | tail -1"
        REMOTE_CMD_ARRAY+=( "${REMOTE_CMD}" )
        ;;
    b)
        # Display uptime
        REMOTE_CMD="hostname && uptime"
        REMOTE_CMD_ARRAY+=( "${REMOTE_CMD}" )
        ;;
    c)
        # Is watchdog active
        REMOTE_CMD="hostname && dmesg | grep watch | tail -1"
        REMOTE_CMD_ARRAY+=( "${REMOTE_CMD}" )
        ;;
    d)
        # Retrieve complete journal log
        REMOTE_CMD="hostname && journalctl --no-pager"
        REMOTE_CMD_ARRAY+=( "${REMOTE_CMD}" )
        ;;
    e)
        # Is HDMI active
        REMOTE_CMD="hostname && /opt/vc/bin/tvservice -s"
        REMOTE_CMD_ARRAY+=( "${REMOTE_CMD}" )
        ;;
    f)
        # Reduce power consumption
        # Switch Wifi / bluetooth off, stop and disable wifi / bluetooth services, power off USB
        REMOTE_CMD="sudo -- bash -c 'rfkill block wifi; rfkill block bluetooth; systemctl stop wpa_supplicant; systemctl stop bluetooth; systemctl stop hciuart; systemctl disable wpa_supplicant; systemctl disable bluetooth; systemctl disable hciuart; systemctl daemon-reload; lspci | grep -q USB && { echo 1 > /sys/bus/pci/devices/0000\:01\:00.0/remove; }'"
        REMOTE_CMD_ARRAY+=( "${REMOTE_CMD}" )
        ;;
    g)
        # List RF devices state, PCI devices (e.g. USB), state of wifi/bluetooth services
        REMOTE_CMD="sudo rfkill list; lspci; systemctl is-active wpa_supplicant ; systemctl is-active bluetooth ; systemctl is-active hciuart"
        REMOTE_CMD_ARRAY+=( "${REMOTE_CMD}" )
        ;;
    h)
        # Re-activate Bluetooth, Services, and USB
        REMOTE_CMD="sudo -- bash -c 'systemctl enable hciuart; systemctl enable bluetooth; systemctl enable wpa_supplicant; systemctl start hciuart; systemctl start bluetooth; systemctl start wpa_supplicant; echo 1 >/sys/bus/pci/rescan; rfkill unblock bluetooth'"
        REMOTE_CMD_ARRAY+=( "${REMOTE_CMD}" )
        ;;
    i)
        # Get various vcgencmd data
        REMOTE_CMD="hostname && vcgencmd get_camera; vcgencmd get_throttled ; vcgencmd measure_temp;  vcgencmd measure_temp pmic; vcgencmd measure_volts core; vcgencmd measure_volts sdram_c; vcgencmd measure_volts sdram_i; vcgencmd measure_volts sdram_p; vcgencmd get_config total_mem; vcgencmd get_mem arm; vcgencmd get_mem gpu; vcgencmd mem_oom; vcgencmd display_power -1 0; vcgencmd display_power -1 1; vcgencmd display_power -1 2; vcgencmd display_power -1 3; vcgencmd display_power -1 7"
        REMOTE_CMD_ARRAY+=( "${REMOTE_CMD}" )
        ;;
    j)
        # retrieve scaling_governor
        REMOTE_CMD="cat /sys/devices/system/cpu/cpufreq/policy0/scaling_governor"
        REMOTE_CMD_ARRAY+=( "${REMOTE_CMD}" )
        ;;
    k)
        # remove scaling governor overwrite
        REMOTE_CMD='grep -q "#echo \"ondemand\"" /etc/init.d/raspi-config || sudo sed "s/echo \"ondemand\"/\#echo \"ondemand\"/" -i /etc/init.d/raspi-config; grep "echo \"ondemand\"" /etc/init.d/raspi-config'
        REMOTE_CMD_ARRAY+=( "${REMOTE_CMD}" )
        ;;
    l)
        # clock down raspberry pi
        REMOTE_CMD="echo powersave | sudo tee /sys/devices/system/cpu/cpufreq/policy0/scaling_governor; cat /sys/devices/system/cpu/cpufreq/policy0/scaling_governor"
        REMOTE_CMD_ARRAY+=( "${REMOTE_CMD}" )
        ;;
    *)
        usage
        exit 1
        ;;
  esac
done



#####################################################
# Main program
#####################################################

[ -e "${REMOTE_SHELL}" ] || {
    echo "Could not find remote shell: ${REMOTE_SHELL}"
    exit 1
}

[ -f "${IP_LIST}" ] || {
    echo "Could not find IP list: ${IP_LIST}"
    exit 1
}

for rcmd in "${REMOTE_CMD_ARRAY[@]}"; do
    #shellcheck disable=SC2002
    cat "${IP_LIST}" | xargs -n 1 -I addr "${REMOTE_SHELL}" addr "CAMNODE" "${rcmd}"
done
