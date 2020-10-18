# Node-specific AutoSetup Scripts for the Raspberry Pi

These instruction describe the creation of the automatic setup scripts of Raspberry Pis for the scanner. There are two main tasks the scripts implement

1. Securing the login to the Raspberry Pi
1. Install the scanner software

## Securing the Raspberry Pi

The Raspberry Pi community provides an [extensive documentation](https://www.raspberrypi.org/documentation/configuration/security.md) on the various ways to secure the Raspberry Pi. 

This project utilizes a ssh login using key-based authentication. At the same time it disables password logins. As a result, the system still provides a shell to run scripts from remote, while having a secured access policy. 

*to be completed* 
https://www.raspberrypi.org/documentation/configuration/security.md

## Software Install Scripts

*tbd*