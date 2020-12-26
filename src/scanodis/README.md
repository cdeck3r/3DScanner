# scanodis - Scanner Node Discovery

scanodis implements the node reverse discovery as a consequence of the network topology. It runs on the centralnode as a hourly cronjob. scanodis calls different reverse discovery approaches. Finally, scanodis runs a link-local discovery for all camnodes in the local network using mDNS.

References to project documentation 

* [scanner network topology](../../../../blob/master/docs/network.md) design and implementation
* [reverse device discovery](../../../../blob/master/docs/reverse_discovery.md)
* [scanodis](../../../../blob/master/docs/scanodis.md) (scanner node discovery)

Relevant scripts:

* `install_scanodis.sh` install the scanodis cronjob
* `scanodis.sh` runs the scanner node discovery trackers

The directory contains the tracker scripts with the naming convention `<double digit>_tracker_<tracker name>.sh`. Each script contains the `publish_to_tracker()` function called by `scanodis.sh` script. These scripts actually implement the discovery function.

At the end of each run, scanodis rotate the log files. The `logrotate.conf` file configures the log rotation.