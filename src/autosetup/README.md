# Autosetup

autosetup configures a node and installs software. As a result, we have either a

* centralnode, or
* camnode

Furthermore, autosetup contains scripts to start the software update process.

The project documentation regarding autosetup

* [autosetup scripts](../../../../blob/master/docs/autosetup_scripts.md)
* [setup process](../../../../blob/master/docs/raspi_setup_process.md)
* [software update process](../../../../blob/master/docs#software-update-process)

Important scripts:

* `create_autosetup.sh` creates node-specific autosetup scripts
* `rerun_autosetup.sh` re-runs the autosetup
* `remote_bash.sh` opens a remote bash shell on a centralnode or camnode

In the sub-directory `tests` one can find pytest unit testcases.