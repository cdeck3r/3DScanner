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
    It generates the ssh keys and let the user define a NODETYPE. The latter serves to control the actions of the autosetup install scripts.
1. Deploy the created `autosetup.zip` on the SD card's root directory.

## Securing the Raspberry Pi

The Raspberry Pi community provides an [extensive documentation](https://www.raspberrypi.org/documentation/configuration/security.md) on the various ways to secure the Raspberry Pi. 

This project utilizes a ssh login using key-based authentication. At the same time it disables password logins. As a result, the system still provides a shell to run scripts from remote, while having a secured access policy. 

*to be completed* 
https://www.raspberrypi.org/documentation/configuration/security.md


## Software Install Scripts

The scripts to run on a Raspberry Pi during the software installation are part of the repository to enable versioning. The `autosetup.sh` script downloads and runs them according to the NODETYPE configured.
