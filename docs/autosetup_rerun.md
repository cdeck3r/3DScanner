# Re-run autosetup

**User story**
> As a developer, I want to restart the autosetup for dedicated nodes, so that incremental installation changes can be automatically applied and tested.

## Approach

On the dev system, the developer starts a script which takes the node same as argument. The script uses ssh as remote shell, deletes the `/boot/booter.done` file and reboots the node.

```bash
rerun_autosetup.sh <nodename-hwaddr>
```