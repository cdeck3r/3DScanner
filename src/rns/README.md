# rns - Remote Node Setup

User story
> As a developer, I want to setup the node remotely, either from the centralnode or the dev system. 

rns remotely copies the files for the autosetup on a node and re-runs the autosetup process afterwards. This is useful, if there is no autosetup.zip file on the node or the developer wants to update the autosetup process. 

The node is required to provide a ssh login. 

References to project documentation 

* [remote node setup](../../../../blob/master/docs#software-update-process)
* [automatic node setup](../../../../blob/master/docs/autosetup.md)

Relevant scripts:

* `rns.sh` runs a remote node setup for a single node 
* `arp_nodelist.sh` performs a arp-scan for Raspberry Pi nodes and outputs them as a list of IP addresses 

