# Manual Software Installation

We discuss two approaches

1. manual process
1. remote node setup to (re-)initialize a node. It will config and (re-)install software within the autosetup process.

## Manual Process

A developer may want to install or change software packages. The developer logs into the centralnode. The centralnode knows the ssh auth keys to login on the camnodes.

* [find camnodes using avahi](scanodis.md#scanodis-link-local-discovery) automatically logs ssh services of all camnodes in the network into `log/nodelist.log`
* [find nodes using arp](../../../tree/master/src/rns) use `arp_nodelist.sh` 

When the developer has ssh'ed into a camnode, she may perform all types of software operations. Similar to ssh, one may use the scp to copy files. 

## rns - remote node setup

Remote node setup (rns) in project's `src/rns` directory remotely copies the files for the autosetup on a node and re-runs the autosetup process afterwards. This is useful, if there is no autosetup.zip file on the node or the developer wants to update the autosetup process. 
All commands utilize ssh and scp commands.

Run `rns.sh` with the following parameters:

```bash
rns.sh <file directory> <node address>
``` 

* `<file directory>` contains files to copy.  Currently, it supports `autosetup_*.zip` and `booter.sh`. 
* `<node address>` name or IP address of Raspberry Pi node to copy files to

rns copies all files into `/boot` directory on the node and re-runs the autosetup through reboot.

Use [xargs](https://man7.org/linux/man-pages/man1/xargs.1.html) to run `rns.sh` for a list of nodes. 
```bash
cat <addr file>  | xargs -n 1 -I addr rns.sh <file dir> addr"
```

The `<addr file>` contains one node address per line. The `-I addr` specifies a freely choosen parameter name, here *addr* for the address from the file. Use this name as the positional argument of `rns.sh`.


**Note:** One may run `rns` directly from the cloned repository in `/boot/autosetup/3DScanner` as regular user. 
