# Raspi Initial Setup

These scripts modify the default raspios image. It adds the booter service to run scripts at the init bootup of the Raspberry Pi in order to configure the Raspi as a scanner node. Afterwards, the end user flashes the image onto the SD card and adds the autosetup.zip file before the first bootup.

References to project documentation 

* [customize raspios image](../../../../blob/master/docs/custom_image.md)
* [install raspios image](../../../../blob/master/docs/install_raspi.md)
* [setup process](../../../../blob/master/docs/raspi_setup_process.md)

Relevant scripts:

* `raspios_download.sh` downloads the raspios image into `3DScannerRepo/raspios`
* `raspios_customize.sh` add systemctl `booter.service` to the raspios image

The `booter.sh` and `booter.service` files describe the systemctl booter service.