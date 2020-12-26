# Raspi autosetup scripts

At the end of the autosetup run, node-specific software installation starts. 

The project documentation mentioning autosetup_scripts

* [Software install scripts](../../../../blob/master/docs/autosetup_scripts.md#software-install-scripts)
* [software install scripts at the end of autosetup](../../../../blob/master/docs/autosetup.md#autosetup)

Relevant scripts:

* `install_commons.sh` installs software common to camnode and centralnode
* `install_camnode.sh` installs software for a camnode 
* `install_centralnode.sh` installs software for a centralnode 

The centralnode installs the mosquitto mqtt broker. The directory contains the `centralnode_mosquitto.conf` config file for the broker.
