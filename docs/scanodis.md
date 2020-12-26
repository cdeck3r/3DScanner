# Scanodis (Scanner Node Discovery)

scanodis implements the [node reverse discovery](reverse_discovery.md). It runs on the centralnode as a hourly cronjob under the `pi` user. scanodis calls different reverse discovery approaches. Finally, scanodis runs a link-local discovery for all camnodes in the local network using mDNS.

## Trackers: Looping through Reverse Discovery Approaches

Reverse discovery approaches track the centralnode's host information. For each approach we store important config information as key/value pairs in the `scanodis_tracker.ini`. The autosetup process on the dev system or the developer add config info to this file. The activity diagram below explains how the cronjob iterates through the various discovery approaches implemented within tracker scripts. As an example we illustrate the call to ethercalc for storing node's host information.

![Activity diagram iterating through reverse discovery trackers](http://www.plantuml.com/plantuml/png/3Sqn3i8m34RXlQU02yH3DwOEt803LCQnQDJ4GVOVmV6RwKbl-RO0EqQhoxsOr95rUBqTm3SUHCw_z2aundk4kdI36fBqHf9LpjLfVRw4pTIfSM0cTmbYsMFkdaliS9PJFHB-M3QrFB4B)

## scanodis ethercalc tracker

In this reverse discovery approach, the node of interest posts its connection details to a public [ethercalc](https://ethercalc.net/) sheet. The sheet URL is created during the autosetup on the developer system and stored as key/value pair config data in `scanodis_tracker.ini`, which becomes part of the `autosetup_centralnode.zip`. The config data is secured on the centralnode Raspberry Pi from access over the network. See ssh via [key-based auth](sshkeys.md).

The following activity diagram displays the actions to create an ethercalc sheet for scanodis during the run of `create_autosetup.sh`. 

![Activity diagram to setup a ethercalc sheet for scanodis](http://www.plantuml.com/plantuml/png/3SYn3G8n30NGLM21kBYEcWqOu6H-B1AHSv3z8nYVgvxqhjqnLhKLuzB8Jzv4Gh_brTdMSwK5fjES1VCGLCDx2zdk3wYxXHoQFAaJAOezpvwrvsvi5j21mX__)

When the `autosetup_centralnode.zip` gets extracted on the node, the `scanodis_tracker.ini` is found in `/boot/autosetup/`.

## scanodis link-local discovery

[User story](https://trello.com/c/sLm77is1):
> As a developer, I want to discover all nodes on a local-link network, so that I learn name and IP about all networked scanner nodes.

The scanner nodes connect with each other in a [local network](network.md#3dscanner-network). Independent from a node-specific software installation, the developer wants to know which node is reachable under which name and IP address. This is helpful in various debug and setup situations. 

All nodes publish their ssh service. The centralnode browses the local domain for all camnodes and resolves their IPv4 addresses. It logs them into the scanodis log directory as `nodelist.log`. Browsing, resolving and logging runs as a tracker script from within the `scanodis.sh` main loop.
