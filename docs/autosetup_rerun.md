# Re-run autosetup

**User story**
> As a developer, I want to restart the autosetup for dedicated nodes, so that incremental installation changes can be automatically applied and tested.

## Approach

On the dev system, the developer starts a script which takes the node same as argument. The script uses ssh as remote shell, deletes the `/boot/booter.done` file and reboots the node.

```bash
rerun_autosetup.sh <nodename-hwaddr>
```

## Unit testing

Unit testing the `rerun_autosetup.sh` script must prove that the re-running the script actually changes the installation. 

1. remove files and test that files are missing
1. remove some selected software packages and test that software packages are removed
1. start `rerun_autosetup.sh`
1. node reboots and re-installs software ... wait at least 120 seconds
1. run `test_autosetup_<..>.py` unit test

The first three steps are part of the `test_rerunautosetup_<..>.py` unit test. The last step runs the standard autosetup unit tests. In between one has to insert a pause to give time for the node to re-install software. Since the unit test modifies installed software packages, the standard test run skips the testcase by default. Override the skip directive in order to actually run the testcase by the following command. The full command line is as follows:

```bash
pytest --force test_rerunautosetup_camnode.py && sleep 120 && pytest test_autosetup_camnode.py
```

Replace `..camnode..` by `..centralnode..` to test it for the centralnode.