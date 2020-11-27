# Homie Device Descriptions

The nodes utilize the [homie convention](https://homieiot.github.io/) to describe themselves using the mqtt topics.

## Devices Descriptions

The following devices describe themselves using homie.

* camnode
* centralnode
* scanner

The scanner device describes the entire technical structure as seen by an external observer. It  aggregates all other device descriptions and creates a new device from them with the camnode and centralnode devices as nodes.

## Approach

What do we model...