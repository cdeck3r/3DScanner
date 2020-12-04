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

# ignore wrong date
apt-get update -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false

# cleanup
apt-get clean && rm -rf /var/lib/apt/lists/*
