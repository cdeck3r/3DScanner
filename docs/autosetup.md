# Automatic Node Setup

The autosetup consists of

1. an initial node setup through the `booter.sh` script run by systemd `booter.service`
1. a node-specific software setup through `autosetup_NODETYPE.zip`

## `booter.sh`

The script performs a very basic Raspberry Pi setup.

* set hostname to `node-<hwaddr>`
* set timezone to Europe/Berlin
* enable ssh 

`booter.sh` performs the initial setup only once. The actions depend on the existence of `/boot/booter.done`. The activity diagram depicts the control flow. 

![booter.sh control flow](http://www.plantuml.com/plantuml/png/3Sqn3i8m34RXlQU02yH3DwOEt803eDInQ4LY8_ktuFXaUdhJjmMg8qTVhgTopoRf_N80dxWHUVsMruaZzmnnDeKe2jiWRiBlrMczFxYgYjEeWPbc75JvkPlDBVXXsKJR5Fu0)

If successfully run, the service creates `booter.done` to indicate the initial run. This will prohibit a repeated run of `booter.sh`.

## autosetup

The `autosetup.sh` script is part of the node-specific `autosetup.zip` archive. After `booter.sh` unzips the archive it hands over the control to the `autosetup.sh` script which performs the node-specific software setup tasks. These tasks consist of

* (re-)set hostname to either ´camnode-<hwaddr>´ or `centralnode-<hwaddr>`   
* secure Raspberry Pi by ssh keys
* install additional system software, e.g. git
* clone the scanner repository

The scripts to run on a Raspberry Pi during the software installation are part of the repository to enable versioning. The `autosetup.sh` script clones the 3DScanner repo and runs the scripts from `raspi-autosetup` directory according to the configured NODETYPE.

The activity diagram depicts the control flow. 

![autosetup.sh control flow](http://www.plantuml.com/plantuml/png/3Ssn4S8m30NGFbF00bQHZYe56p009sGToM7BEUdhO7nSlV9j0NPaRylrC6bPDRrTTk2C6v7pjxmFxFdAK9TXK4EHqKcgocTrMkyFOJDrwXoOr251B4zEZ53aMV33igdLcVm1)

## Start autosetup from `booter.sh`

The `booter.sh` script looks for the `autosetup_NODETYPE.zip`. It will prefer the `autosetup_camnode.zip` over the `autosetup_centralnode.zip`, if it exists. It extracts the files into `autosetup` directory. Afterwards it runs the `autosetup.sh`. The following activity diagram depicts the control flow.

![start autosetup from booter.sh](http://www.plantuml.com/plantuml/png/3ST13i9020NGg-W5XaLthhs11sWeGsnZ2nFuH8_lh5xU_J0vgsl5UTk1aG-Yu6zx7zXhgzGGDwYXYLyaNUMp12tFbx2P1bsSc7IN99PrSvzTkU2fgD7mmny0)

## Unit Testing

We use [pytest-testinfra](https://github.com/pytest-dev/pytest-testinfra) for unit testing the autosetup. It is the python pendant of [ServerSprec](https://serverspec.org/) for checking server configurations. It tests for ssh logins and the successful software installation. There are no dedicated tests for `booter.sh`, because autosetup changes booter-specific parts. 

Configure tests in `src/autosetup/tests`

1. open `pytest.ini`
1. set names for camnode and centralnode

Run tests by issuing the following command from within the dockerized dev system:

```
cd src/autosetup/tests
pytest
```

There are the different testcases available:

* `test_basic_[cam|central]node.py`: ping node
* `test_ssh_[cam|central]node.py`: performs various ssh logins using ssh keys
* `test_autosetup_[cam|central]node.sh`: checks various results from autosetup run