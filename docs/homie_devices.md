# Homie Device Descriptions

The nodes utilize the [homie convention](https://homieiot.github.io/) to describe themselves using the mqtt topics.

## Devices Descriptions

The following devices describe themselves using homie.

* camnode
* centralnode
* scanner apparatus

The scanner apparatus describes the entire technical structure as seen by an external observer. It  aggregates all other device descriptions and creates a new device from them with the camnode and centralnode devices as nodes.

The base topic for all devices is `scanner`.

## Device Attributes

Each device (camnode, centralnode) has the following attributes.

Base topic: `scanner/`

| Device           | Attribute       | Sub-Attribute | Notes                       |
|------------------|-----------------|---------------|-----------------------------|
| ...node-`<hwaddr>` | $name           |               | displays camnode-`<hwaddr>`   |
|                  | $implementation |               | ex. Raspberry Pi, or x86_64 |
|                  | $fw             | name          | Linux distro name           |
|                  | $fw             | version       | kernel version              |


## camnode

Complementary to the device attributes, a camnode device has the following relevant nodes and properties.

Base topic: `scanner/` 

| Device           | Node       | Property       | Notes                                          |
|------------------|------------|----------------|------------------------------------------------|
| camnode-`<hwaddr>` | camera     | shutter-button | hit the button to take a picture               |
|                  | software   | repo-revision  | SHA revision of the repository's master branch |
|                  |            | local-revision | SHA revision of the local's repo master branch |
|                  | last-image | name           |                                                |
|                  |            | datetime       |                                                |
|                  |            | file           | camnode published images as binary file        |


## Centralnode

Complementary to the device attributes, a camnode device has the following relevant nodes and properties.

Base topic: `scanner/` 

...tbd...

## Scanner apparatus

...tbd...
