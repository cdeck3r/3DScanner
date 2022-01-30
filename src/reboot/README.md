# reboot

Reboot the CENTRALNODE and run jobs.

## Situation

At a daily intervall we want to restart the scanner. This shall take care of hung-up processes or network hick-ups, which may set scanner nodes partially offline. 

This becomes even more important after a network failure when the CENTRALNODE is assigned a new IP address or scanodis does not report the address anymore. In this case, the end-user looses the ability to access the scanner's UI and image files.


## Approach

1. Implement a nightly reboot of the CENTRALNODE
1. After reboot run scanodis _twice_ to get a fresh `nodelist.log`. 
1. Finally, restart the camnode services on all camnodes.

The scanodis run will create a fresh `nodelist.log`, which removes all offline CAMNODES from a previous list. It runs twice to logrotate away the previous nodelist.
Furthermore, it registers the CENTRALNODE, so that the end-user is informed on the new IP address to access the scanner's UI and image files,