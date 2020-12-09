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

2. Deploy the created `autosetup_NODETYPE.zip` on the SD card's root directory.

The `autosetup_NODETYPE.zip` contains:

* ssh keys
* NODETYPE definition file (contains the nodetype as string) 
* autosetup.sh - the install starter script

## Securing the Raspberry Pi

The Raspberry Pi community provides an [extensive documentation](https://www.raspberrypi.org/documentation/configuration/security.md) on the various ways to secure the Raspberry Pi. 

This project utilizes a ssh login using key-based authentication. At the same time it disables password logins. As a result, the system still provides a shell to run scripts from remote, while having a secured access policy. 

Despite the disabled login, the script `src/autosetup/remote_bash.sh` utilizes the key-based authentication to start a remote bash shell. Run the following command on the dev system to find yourself on the node's shell prompt.

```bash
src/autosetup/remote_bash.sh <node name, e.g. camnode-dca632b40802>
``` 

Section [*SSHkey Distribution to Secure Access to the Nodes*](sshkeys.md) contains detailed information on ssh key distribution across the nodes. 

## Software Install Scripts

The scripts to run on a Raspberry Pi during the software installation are part of the repository to enable versioning. The `autosetup.sh` script clones the 3DScanner repo and runs the scripts from `raspi-autosetup` directory according to the NODETYPE configured.

