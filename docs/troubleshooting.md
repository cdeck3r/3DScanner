# Troubleshooting

This documentation provides some guidelines to correct the scanner in case of non-desireable behavior. Please read the [user manual](user_manual.md) beforehand. 

## Health Status

This section describes a series of actions to analyze and document the scanner's current status. If you experience an undesireable behavior, please run the following checks. 

* Check [scanner's health status](user_manual.md#scanner-health-status)
    1. Does it show the success message?
    1. Take a screenshot and send it to developer

* Hit [`Restart camera node service`](user_manual.md#restart-camera-service) 
    1. Does it show the success message?
    1. try again taking pictures with the scanner
    
* List all [online cameras](user_manual.md#list-all-online-cameras)
    1. Does it show the success message?
    1. Take a screenshot and send it to developer

If you still experience an undesireable behavior, restart the CENTRALNODE Raspberry Pi. 

* To restart the CENTRALNODE Raspberry Pi - proceed with the following actions 
    1. pull the power plug from the CENTRALNODE
    1. wait 10min 
    1. power up the CENTRALNODE again
    1. try again taking pictures with the scanner
    
## No new pictures

**Observation:** The scanner seems to take pictures, but pictures are not downloaded.

**Assumed reason:** CAMNODEs are disconnected or scanner apparatus is disconnected

**Actions to be taken:**

1. Hit [`Restart camera node service`](user_manual.md#restart-camera-service) and try again
1. Restart the CENTRALNODE Raspberry Pi - proceed with the following actions 
    1. pull the power plug from the CENTRALNODE
    1. wait 10min 
    1. power up the CENTRALNODE again
    1. try again
    
## Less pictures than expected

**Observation:** Receive less pictures than available camera nodes

**Assumed reason:** Either not all camera nodes are online, or the download partially failed.

**Actions to be taken:**

1. Hit [`Restart camera node service`](user_manual.md#restart-camera-service) and try again
1. Future feature: Identify the failed camera node, restart the failed camera node by pulling out the USB plug, wait 1 min and re-connect it, wait 5min and try again.

## Uplink Disconnect

**Observation:** The uplink to the Internet is disconnected.

**Assumed reason:** All devices are offline, because there is no internet connection.
 
**Actions to be taken:**

1. Reconnect the uplink
1. Wait for the network to rebuild...
    1. Wait for the next day. Throughout the day, several mechanism will re-establish the network connections between all scanner nodes 
    1. If you can't wait a day, please proceed with the following actions
        1. pull the power plug from the CENTRALNODE
        1. wait 10min 
        1. power up the CENTRALNODE again
        1. go to the [user UI](user_manual.md#user-interface-documentation)
        1. hit [`Restart camera node service`](user_manual.md#restart-camera-service)
        1. ... try again.

## Accidential Disconnect

**Observation:** By accident, the you have 

* restarted the network router 
* disconnected the CENTRALNODE
* removed the power-plug

**Assumed reason:** The network is down.

**Actions to be taken:**

1. Connect all network cables
1. Power-up the router
1. Restart the CENTRALNODE Raspberry Pi - proceed with the following actions 
    1. pull the power plug from the CENTRALNODE
    1. wait 10min 
    1. power up the CENTRALNODE again
    1. try again
