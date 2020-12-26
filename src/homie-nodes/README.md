# homie-nodes

The nodes utilize the [homie convention](https://homieiot.github.io/) to describe themselves using the mqtt topics.

![works with MQTT Homie](https://homieiot.github.io/img/works-with-homie.png) 

The project documentation regarding homie nodes

* [Homie device description](../../../../blob/master/docs/homie_devices.md)
* [Homie device service](../../../../blob/master/docs/homie_device_service.md)

Relevant scripts:

* `install_homie_service.sh` installs the nodes as homie devices
* `homie-camnode` directory contains the Homie 4.0 device description for camnodes
* `homie-centralnode` directory contains the Homie 4.0 device description for centralnode

In the sub-directory `tests` one can find pytest unit testcases.