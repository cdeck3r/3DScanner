#!/bin/bash
set -e

#
# Install scanner software for cam(era)nodes 
# 
# Author: cdeck3r
#

# Params: none 

# Exit codes
# >0 if script breaks


# ignore wrong date
apt-get update -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false

apt-get install -y \
    python3-pip \
    mosquitto-clients

# cleanup
apt-get clean && rm -rf /var/lib/apt/lists/* 

# homie convention https://github.com/mjcumming/homie4
pip3 install Homie4