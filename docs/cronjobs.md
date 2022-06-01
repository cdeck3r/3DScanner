# Periodic processes to maintain the system

Periodic processes run at defined intervals to maintain some system functions. The processes are implemented as cronjobs.

## CENTRALNODE

These are the cronjobs running on the CENTRALNODE. If not otherwise state, these are daily cronjobs.

| Time    | User | Script                                                            |
|---------|------|-------------------------------------------------------------------|
| hourly  | pi   | Run [scanodis](../src/scanodis)`                                  |
| 1:30am  | root | `shutdown -r now`                                                 |
| 2am     | pi   | Run [script-server](../src/script-server) logrotate               |
| 2am     | pi   | Run [reboot](../src/reboot) logrotate                             |
| (Sun) 2:30am  | pi   | Run [reboot](../src/reboot) all camnodes                    |
| 2:30am  | pi   | Run [housekeeping](../src/housekeeping) logrotate                 |
| 3am     | pi   | Run [housekeeping](../src/housekeeping) for `/home/pi/www-images` |
| 3:30am  | pi   | Run [housekeeping](../src/housekeeping) for `/home/pi/tmp`        |
| @reboot | pi   | Run [reboot](../src/reboot/)                                      |
| @reboot | root | Run `avahi-resolve-name-conflict.sh`                              |


## CAMNODE

These are the cronjobs running on each CAMNODE. If not otherwise state, these are daily cronjobs.

| Time    | User | Script                                                            |
|---------|------|-------------------------------------------------------------------|
| 2:30am  | pi   | Run [housekeeping](../src/housekeeping) logrotate                 |
| 3am     | pi   | Run [housekeeping](../src/housekeeping) for `/home/pi/images`     |
| @reboot | root | Run `avahi-resolve-name-conflict.sh`                              |

