# reboot

Reboot scanner nodes to maintain a clean state. The scripts reboot the CENTRALNODE as well as all CAMNODES. All scripts run on the CENTRALNODE started by [cronjobs](../../docs/cronjobs.md). 

## Situation

At a daily intervall we want to restart the scanner. This shall take care of hung-up processes or network hick-ups, which may set scanner nodes partially offline. 

This becomes even more important after a network failure when the CENTRALNODE is assigned a new IP address or [scanodis](../scanodis/) does not report the address anymore. In this case, the end-user looses the ability to access the scanner's UI and image files.

After a long uptime of all CAMNODES there is a high risk that the CAMNODES will fail to properly startup after a reboot. This situation occurred once in the mid February 2022 update after a 300 days uptime of each CAMNODE. 

## Approach

The CENTRALNODE controls the reboot of the CENTRALNODE and all CAMNODES. [Cronjobs](../../docs/cronjobs.md) start the reboot activities.

**CENTRALNODE**

1. Implements a nightly reboot of the CENTRALNODE.
1. After reboot run [scanodis](../scanodis/) _twice_ to get a fresh `nodelist.log`. 
1. Finally, restart the camnode services on all camnodes.

The [scanodis](../scanodis/) run will create a fresh `nodelist.log`, which removes all offline CAMNODES from a previous list. It runs twice to logrotate away the previous nodelist.
Furthermore, it registers the CENTRALNODE, so that the end-user is informed on the new IP address to access the scanner's UI and image files.

**CAMNODES**

We reboot CAMNODES one at a time with a 5min delay in between. It shall prevent an  strong intermediate power surge causing a voltage level drop, which potentiall let Raspberry Pis crash. One CAMNODE reboot at a time minimizes the impact on the scanner's overall power supply.

1. Implements Weekly reboot of all CAMNODES.
1. Before reboot log the number of nodes from `nodelist.log`.
1. For each camnode from `nodelist.log`
    1. Stop `homie_camnode.service`
    1. Set `powersave` mode
    1. Switch off green LED
    1. Schedule reboot command with 5min delay to previous reboot command. 
1. After last reboot run scanodis _twice_ to get a fresh `nodelist.log` and log the number of nodes.

With approx. 50 camnodes installed, the staggered reboot takes about 250min (more than 4 hours). As a consequence, the CAMNODE reboot runs weekly only on Sundays in the morning hours. See [cronjobs](../../docs/cronjobs.md) documentation.

## Scripts

* `reboot_centralnode.sh`: runs [scanodis](../scanodis/) after reboot
* `reboot_camnodes.sh`: schedules reboots on each camnode; one at a time with a 5min delay in between
* `install_reboot.sh`: install all script cronjobs and logrotation for `logrotate.conf` 