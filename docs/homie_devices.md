# Homie Device Descriptions

The nodes utilize the [homie convention](https://homieiot.github.io/) to describe themselves using the mqtt topics.

## Devices Descriptions

Devices are abstraction for scanner components and functions and describe themselves using homie. The following class diagram depicts three homie devices.

* camnode
* centralnode
* scanner apparatus

![Class diagram of homie devices](http://www.plantuml.com/plantuml/png/3SN14K8X30JGLhG1SlWtptPW0Gmk6M64u2IBMhw-opjtmzXLjuzJ8rzn4V7oIO_EjkyxrB6CQanOKr0LpyFbkDvGpDHbbk2_kX22KI9oMxDhhlhkq4ZyyWS0)

The scanner apparatus describes the entire technical structure, referred to as `<<system>> scanner`, as seen by an external observer. It depends on the other device descriptions from the camnode and centralnode devices.

The base topic for all devices is `scanner`.

## Device Attributes

Each device (camnode, centralnode) has the following attributes.

Base topic: `scanner/`

| Device           | Attribute       | Sub-Attribute | Notes                       |
|------------------|-----------------|---------------|-----------------------------|
| ...node-`<hwaddr>` | $name         |               | displays camnode-`<hwaddr>` |
|                  | $implementation |               | ex. Raspberry Pi, or x86_64 |
|                  | $fw             | name          | Linux distro name           |
|                  | $fw             | version       | kernel version              |


## Camnode

Complementary to the device attributes, a camnode device has the following relevant nodes and properties.

Base topic: `scanner/` 

| Device           | Node       | Property       | Notes                                          |
|------------------|------------|----------------|------------------------------------------------|
| camnode-`<hwaddr>` | camera   | shutter-button | push the button to take a picture              |
|                  |            | shutter-timer  | time in ms to wait before taking a picture     |
|                  |            | resolution-x   | resolution width which image is captured       |
|                  |            | resolution-y   | resolution height which image is captured      |
|                  |            | def-resolution | (reset) default resolution from local config file |
|                  |            | revision       | revision of the Pi’s camera module             |
|                  | software   | repo-revision  | SHA revision of the repository's master branch |
|                  |            | local-revision | SHA revision of the local's repo master branch |
|                  | recent-image | filename     | most recent image taken by the camera          |
|                  |            | datetime       | Image modification time YYYY-MM-DDTHH:MM:SS.ssssss |
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

The homie [camnode device implementation](https://github.com/cdeck3r/3DScanner/tree/master/src/homie-nodes/homie-camnode) loads configuration settings from  [`homie_camnode.yml`](https://github.com/cdeck3r/3DScanner/blob/master/src/homie-nodes/homie-camnode/homie_camnode.yml).


## Centralnode

Complementary to the device attributes, a centralnode device has the following relevant nodes and properties.

Base topic: `scanner/` 

...tbd...

## Scanner apparatus

The scanner apparatus is a homie device describing the entire technical structure as seen by an external observer. It runs on the centralnode by default, but it is not limited to. 

Complementary to the device attributes, a apparatus device has the following relevant nodes and properties.

Base topic: `scanner/` 

| Device    | Node          | Property         | Notes                                                                             |
|-----------|---------------|------------------|-----------------------------------------------------------------------------------|
| apparatus | cameras       | shutter-button   | triggers all cameras at the same time                                             |
|           |               | last-button-push | datetime "yyy-mm-dd HH:mm:ss" of last shutter button pressed                      |
|           |               | online           | cameras online and ready for taking picures                                       |
|           |               | online-percent   | percentage value of cameras online                                                |
|           | recent-images | save-all         | retrieve recent images from all cameras and make  them accessible to the end-user |
|           |               | last-saved       | datetime "yyyy-mm-dd HH:mm:ss" of most recent images                              |
|           |               | image-count      | number of images retrieved at last update                                         |                                    |

1. Let all cameras on the camnodes take pictures.

```
mosquitto_pub -h <broker> -t scanner/apparatus/shutter-button/set -m push
```

2. Run `save-all` to retrieve all images from the camnodes and store them.

```
mosquitto_pub -h <broker> -t scanner/apparatus/recent-images/save-all/set -m run
```

The homie [apparatus device implementation](https://github.com/cdeck3r/3DScanner/tree/master/src/homie-nodes/homie-apparatus) loads configuration settings from  [`homie_apparatus.yml`](https://github.com/cdeck3r/3DScanner/blob/master/src/homie-nodes/homie-apparatus/homie_apparatus.yml).
