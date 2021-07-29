# Logging and Housekeeping

The 3DScanner software components produce constantly log information and may store a massive amount of image data. The primary places for data storage are:

* `/home/pi/log` is the default log directory
* `~/www-images` stores the images from all camera nodes on the centralnode

## Logging and Logrotation

A few software components write logfiles in form of proprietary formats the default log directory. They all run on the centralnode. Currently, there is no need for the log directory on the camnodes. The software parts are:

* [scanodis](scanodis.md)
* [script-server UI](script-server_ui.md)

Each performs its own logrotation using the following convention:

1. Defines its own `logrotate.conf` file to be run with `/usr/sbin/logrotate`. 
1. The install script implements a cronjob in the user space to run logrotation at regular intervals. Call `crontab -l` to review the cronjobs.

The [homie services](homie_device_service.md) run within the user-based systemd context and write their logs to the stdout stream. [journalctl](https://www.freedesktop.org/software/systemd/man/journalctl.html) may be used to view and query the systemd logs. The operating system takes care of the log management for systemd.


## Image Housekeeping

The [homie devices](homie_devices.md) on the centralnode and each camnode create images. In particular, centralnode's `www-images` directory stores all images from all camnodes. This piles-up a massive amount of data. It is required to manage the available storage space to keep the nodes operational.

The [housekeeping script](../src/housekeeping) runs on each node and observes the following directories defined in the config files, [homie_camnode.yml](../src/homie-nodes/homie-camnode/homie_camnode.yml) and [homie_apparatus.yml](../src/homie-nodes/homie-apparatus/homie_apparatus.yml), of the homie devices. The directories below are 

* `~/www-images` directory on centralnode
* `~/tmp` on centralnode
* `~/images` directory on each camnode

Image housekeeping runs in regular intervals, on demand or when special events occur. The regular intervals runtime uses a `cronjob` and ensures that slowly increasing leftover data is deleted. A special event is when an end-user fires all scanner cameras. Perform a check at such an occurance makes the system aware on a rapid change in the storage consumption.

The housekeeping process works as follows:

1. Check for free space. Parameter `low watermark` defines the permitted lower bound.
1. In case, we are below the low watermark, we start deleting the oldest files / directories until we are above the `high watermark` parameter.

It is `low watermark < high watermark`. The process basically defines a hysteresis. 

