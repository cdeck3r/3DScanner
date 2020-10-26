# Node-specific AutoSetup Scripts for the Raspberry Pi

These instruction describe the the automatic setup scripts of Raspberry Pis for the scanner. There are two main tasks the scripts implement

1. Securing the login to the Raspberry Pi
1. Install the scanner software

The automatic setup is an archive `autosetup.zip` containing all data and scripts. The end-user deploys the archive onto the SD card's root directory flashed with the [customized image](custom_image.md).

## Create AutoSetup Archive

1. Start the process 
```bash
src/autosetup/create_autosetup.sh
```
It generates the public and private ssh keys for the login on the camnodes. For each nodetype (either CAMNODE or CENTRALNODE) it creates a `autosetup_NODETYPE.zip`.
1. Deploy the created `autosetup_NODETYPE.zip` on the SD card's root directory.

The `autosetup_NODETYPE.zip` contains:

* ssh keys, that is 
    * `camnode` file in `autosetup_centralnode.zip` or 
    * `camnode.pub` file in `autosetup_camnode.zip`
* NODETYPE definition
* autosetup.sh

## Securing the Raspberry Pi

The Raspberry Pi community provides an [extensive documentation](https://www.raspberrypi.org/documentation/configuration/security.md) on the various ways to secure the Raspberry Pi. 

This project utilizes a ssh login using key-based authentication. At the same time it disables password logins. As a result, the system still provides a shell to run scripts from remote, while having a secured access policy. 

## Software Install Scripts

The scripts to run on a Raspberry Pi during the software installation are part of the repository to enable versioning. The `autosetup.sh` script clones the 3DScanner repo and runs the scripts from `raspi-autosetup` directory according to the NODETYPE configured.

## Start from `booter.sh`

The `booter.sh` script looks for the `autosetup_NODETYPE.zip`. It will prefer the `autosetup_camnode.zip` over the `autosetup_centralnode.zip`, if it exists. Unzip extracts the files into `autosetup` directory. Afterwards it runs the `autosetup.sh`.

![start autosetup from booter.sh](http://www.plantuml.com/plantuml/png/3ST13i9020NGg-W5XaLthhs11sWeGsnZ2nFuH8_lh5xU_J0vgsl5UTk1aG-Yu6zx7zXhgzGGDwYXYLyaNUMp12tFbx2P1bsSc7IN99PrSvzTkU2fgD7mmny0)

