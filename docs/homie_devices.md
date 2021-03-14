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
| camnode-`<hwaddr>` | camera     | shutter-button | push the button to take a picture               |
|                  |      | shutter-timer | time in ms to wait before taking a picture               |
|                  | software   | repo-revision  | SHA revision of the repository's master branch |
|                  |            | local-revision | SHA revision of the local's repo master branch |
|                  | recent-image | filename           | most recent image taken by the camera                                                |
|                  |            | datetime       |                                                |
|                  |            | file           | camnode published images as json formatted base64 encoded file        |


Send a *push* message to the shutter button of the camera will take a picture and update the recent-image properties.

```
mosquitto_pub -h <broker> -t scanner/<device>/camera/shutter-button/set -m push
```

There is also a shutter-button using a delay timer:

1. Set the delay, e.g. 7000ms:

```
mosquitto_pub -h <broker> -t scanner/<device>/camera/shutter-timer/set -m 7000
```

2. Activate the timer:

```
mosquitto_pub -h <broker> -t scanner/<device>/camera/shutter-button/set -m timer
```

After the time exceeded, the camera will take a picture and update the recent-image properties.

## Centralnode

Complementary to the device attributes, a centralnode device has the following relevant nodes and properties.

Base topic: `scanner/` 

...tbd...

## Scanner apparatus

The scanner apparatus is a homie device describing the entire technical structure as seen by an external observer. It runs on the centralnode by default, but it is not limited to. 

Complementary to the device attributes, a apparatus device has the following relevant nodes and properties.

Base topic: `scanner/` 

| Device    | Node     | Property    | Notes                                                                             |
|-----------|---------------|------------------|-----------------------------------------------------------------------------------|
| apparatus | camera       | shutter-button   | triggers all cameras at the same time                                             |
|           |               | last-button-push | datetime "yyy-mm-dd HH:mm:ss" of last shutter button pressed                      |
|           |               | online           | cameras online and ready for taking picures                                       |
|           |               | online_percent   | percentage value of cameras online                                                |
|           | recent-images | store-images     | retrieve recent images from all cameras and make  them accessible to the end-user |
|           |               | last-update      | datetime "yyyy-mm-dd HH:mm:ss" of most recent image                              |

