# Homie Device Service

The scanner's [homie devices](homie_devices.md) run as `systemd` user service. It starts the python script which publishes the homie device descriptions to the centralnode's mqtt broker.

## Installation

The autosetup's node-specific install scripts copy the service files to the `pi` user directory. They enable and start the service. The service install script is `src/homie-nodes/install_homie_service.sh`. It must run as user `pi`. The example lists the files to run the homie device service.

* `homie_camnode.py` the actual homie device program to run as service, found in `src/homie-nodes/homie-camnode`
* `homie_camnode.service` is the systemd service unit file; describes what and how to run as a service

For the centralnode service, replace camnode with centralnode in the above example.

Re-installation of the device services will stop and disable the previously running service. A new service file is copied over and systemd is reloaded. Afterwards it enables and starts the service.

The following sequence diagram displays the homie service installation procedure for the camnode. Important to note is the change in the user under which the script is executed.

![Homie service install procedure as UML sequence diagram](http://www.plantuml.com/plantuml/png/3Skn4O8X30RGLNG1KloTjHiu08SX9paXQFAXZY_LgzvPZVkgihoV6l2A2v6NRteeshgl4ETf44FYEOYhyFDmEgutBcRYD4fWKoS7XRnpcqCbx_PHbgmMABqd_F07)

The installation enables the service start at each Raspi boot-up for the user `pi`. This is the part of the following command:

```bash
loginctl enable-linger pi
```

More details on systemctl user services provides the UNIX sysadmin site:  https://www.unixsysadmin.com/systemd-user-services/

## Runtime

systemd starts the node-specific homie device as `pi` user after the Raspi boot-up completes. It monitors the homie device services and restarts them in case of an error or unexpected exit. 

Us the following commands for a fine-grained control on the service. The examples refer to the homie camnode service. For centralnode control, replace camnode with centralnode. 

```bash
# obtain status, e.g. active or inactive
systemctl --user --no-pager status homie_camnode.service

# stop currently running service, afterwards the service is inactive
systemctl --user --no-pager stop homie_camnode.service

# ... start
systemctl --user --no-pager start homie_camnode.service
```