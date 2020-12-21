# Networking

The 3DScanner Raspberry Pi devices require an Internet connected network to get configured and to retrieve software updates from the GitHub repository. Various network connect with each other:

* scanner network
* uplink network to the scanner network
* Internet

We assume an DHCP service in the uplink network. The Raspberry Pis have access to the public Internet, in particular to the GitHub.com based software repository. However, access from the Internet is restricted, in particular, a firewall prohibits any access to the scanner network from the public Internet. Nevertheless, the developer is able to remotely access the uplink network using VPN. 

The network diagram below depicts how the various components are interconnected.

![Networking](http://www.plantuml.com/plantuml/png/3SN14S9020NGLhI1vP2RPpkm06S5ncIIm0vyPYtVlCkxRyP7YLOSjnKO-I2AFjjtmrgVIWrsWneQ-qaioliIj3nVtCqqwEo9At5Eal4snVJOi-67Fm00)


## 3DScanner network

The scanner's Raspberry Pi devices, these are the camnodes and the centralnode, connect to a single switch. This local network may contain an optional desktop PC. A user or a developer may have direct access to the nodes using this PC. All shell access is secured by [ssh key authentication](sshkeys.md). Within the scanner's local network, nodes discover themselves using [mDNS](https://en.wikipedia.org/wiki/Multicast_DNS)

The local scanner network links to an uplink network, where the end-user may utilize a desktop PC or smartphone to control the 3Dscanner. The uplink network provides a Internet connection, so that the nodes access the software repository at GitHub.com.


## Usage and uplink network

The uplink network is sandwiched between the scanner network and the Internet. The end user is connected via WiFi or wired to the uplink network. The router in this network connects the computer devices to the local scanner network. The uplink network is an as-it-is network, i.e. it pre-existed before the scanner and the scanner simply links to this network by its switch.

A web browser displays the GUI to the end-user. The centralnode in the scanner network provides the GUI.

A firewall secures the access to the uplink network from the Internet.

## Addressing

All Raspberry Pis and other computer devices retrieve their IP addresses from the DHCP server in the uplink network. As a consequence, there is no additional address management required. No separate DHCP service is required, making the scanner useable in all networks providing a DHCP service. Since there is only a single DHCP service, this approach also avoids the conflicts when installing an second DHCP one.


## Remote Access

The developer utilizes a VPN connection to access the uplink network. From there, the developer is able to remotely ssh into the centralnode or any of the camnodes. Since the IP address is dynamically provided by the DHCP service from the uplink service and the mDNS discovery does not work across networks, the developer needs to know a node's IP address. The centralnode implements a [scanodis (scanner node discovery)](reverse_discovery.md) to realize an reverse discovery. The scanodis function provides the centralnode's IP address to the developer. From the centralnode one can discover all camnodes using mDNS and ssh into them using ssh key authentication.

