# Documentation

## Quickstart

**Target group: end-users**

1. Get the customized image and node-specific `autosetup.zip` file 
1. Flash the image and copy the `autosetup.zip` file into the SD card's root directory
1. Insert the SD card into the Raspberry and power it on for booting
1. Point your browser to the URL http://CENTRALNODE/ui (the developer will tell you) and run the [user interface](user_manual.md)


## Operation 

**Target group: end-users**

* [UI manual](user_manual.md) 
* [Troubleshooting guide](troubleshooting.md)

**Target group: developers**

* [Logging and housekeeping](logging_housekeeping.md)
* [Scheduled cronjobs](cronjobs.md) for maintenance
* [HTTP-enabled Dynamic DNS](dyndns.md) to access the scanner UI
* [Web-based User Interface](script_server_ui.md) with script-server
* [Watchdog](watchdog.md) when the system unexpectedly stops operating

## Setup and Install Raspberry Pis

**Target group: developers**

* [Customize image](custom_image.md)
* [Install image on SD Card](install_raspi.md)
* [Build node-specific autosetup scripts](autosetup_scripts.md)
* [sshkey distribution](sshkeys.md)

Complete flow chart of the setup and installation process:

* [Setup process](raspi_setup_process.md)

## Networking

* [Scanner network](network.md) design and implementation
* [Device discovery](reverse_discovery.md)
* [scanodis](scanodis.md) (scanner node discovery)

## Software Update Process

**Target group: developers**

* [Initial node setup](autosetup.md) including unit testing
* [Re-run autosetup](autosetup_rerun.md)
* [Install software manually](manual_sw_install.md) and remote node setup (rns)

## Device Description

* [Homie device description](homie_devices.md)
* [Homie device service](homie_device_service.md)


## Software Development

* [Dev and Prod](dev_prod.md)
* [Code quality](codequality.md)
