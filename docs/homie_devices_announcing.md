# Announcing Nodes

The scanner's [homie devices](homie_devices.md) announce themselves using `systemd` user service. It starts the python script which publishes the homie device descriptions to the centralnode's mqtt broker.

## Installation

The autosetup's node-specific install scripts copy the service files to the `pi` user directory, enable and start the service. The service install script is `src/homie-nodes/install_node_services.sh`. The example shows the files to install and run the homie device service required by the script.

* `homie_camnode.py` the actual program to run as service
* `homie_camnode.service` is the systemd service unit file; describes what and how to run as a service

For the centralnode service, replace camnode with centralnode in the above example.

Re-installation of the device services will stop and disable the previously running service. A new service file is copied over and systemd is reloaded. Afterwards it enables and starts the service.

## Runtime

systemd monitors the homie device services. It restarts them in case of an error or unexpected exit. 
