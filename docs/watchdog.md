# Watchdog

All nodes utilize a hardware watchdog. If the systems unexpectedly stalls, the watchdog will issue a reboot. It is configured via the systemd's `system.conf` file. After an additional reboot, it is active. The system manager keeps the watchdog device `/dev/watchdog` open. An access via will result `sudo wdctl` in an error indicating effectively an active watchdog. 

There is only a minimum on configuration parameters used. The nodes use the plain hardware watchdog. No additional watchdog package is installed to allow the definition of other ressources, e.g. files, network reachability, to part of the watchdog. 


## Rationale 

As a result of nodes not completely rebooting after a software update, the watchdog was introduced. Although in this case the software update was not the root cause of the fault, a developers wants to retain remote access to the nodes after unexpected events have crashed the system. A reboot triggered by a watchdog may resolve such a situation through a reboot. However, one has to be careful with expectations:
 
**Pro watchdog**

* easy to setup via systemd
* watchdog actually intended to resolve a problems when rebooting 

**Con watchdog**

* Sporadic reboots due to unknown side effects with other software components 
* While the watchdog can handle reboot problems, it is not completely clear whether it will have an effect in the situation as a result of the update 
* risk of reboot loop 

**Mitigation**

* Monitoring of uptime to detect sporadic reboots
* Direct (local) observation of nodes to discover a possible reboot loop


## Check Watchdog 

Run the command below to test the watchdog is active. The output of the last line tells you about the watchdog's runtime.

```bash
$ journalctl --no-pager -k | grep watchdog 

... kernel: bcm2835-wdt bcm2835-wdt: Broadcom BCM2835 watchdog timer
... systemd[1]: Hardware watchdog 'Broadcom BCM2835 Watchdog timer', version 0
... systemd[1]: Set hardware watchdog to 10s.
```

## Install Watchdog

The watchdog gets installed in the `install_commons.sh` script during the [setup process](raspi_setup_process.md).


