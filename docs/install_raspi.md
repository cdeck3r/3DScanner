# Install Raspberry Pi

Tested with

* Raspberry Pi 4 model B with 2GB RAM
* [Project specific RaspiOS image](custom_image.md) 
* [node-specific `.zip` file](autosetup.md) containing the setup scripts and ssh keys to secure the Pis


## Bare Raspberry Pi Setup 

These instructions describe the initial setup of an unboxed, brand-new Raspberry Pi. 

Tools

* [SD Formatter portable](https://sourceforge.net/projects/thumbapps/files/Utilities/SD%20Card%20Formatter/): format SD card
* [Etcher](https://github.com/balena-io/etcher/releases/download/v1.5.102/balenaEtcher-Portable-1.5.102.exe): create bootable SD card from image; 
* putty / [WinSCP 5.17.7](https://winscp.net/download/WinSCP-5.17.7-Portable.zip): ssh to raspberry pi


### Prepare RaspiOS

1. Format SD card using SD formatter
1. Flash the image using Etcher
1. Unzip the node-specific `.zip` file into SD card's root directory

### Boot and Verify Login

1. Insert SD card into raspberry Pi and bootup
1. SSH into pi
    


