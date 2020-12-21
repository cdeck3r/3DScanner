# Scanodis (Scanner Node Discovery)

scanodis implements the [node reverse discovery](reverse_discovery.md). It runs on the centralnode as a hourly cronjob under the `pi` user. scanodis may call different reverse discovery approaches.

## scanodis ethercalc 

In this reverse discovery approach, the node of interest posts its connection details to a public [ethercalc](https://ethercalc.net/) sheet. The sheet URL is created during the autosetup on the developer system and stored in the `autosetup_centralnode.zip`. This data is secured on the centralnode Raspberry Pi from access over the network. See ssh via [key-based auth](sshkeys.md).

## scanodis link-local discovery

*...tbd...*
