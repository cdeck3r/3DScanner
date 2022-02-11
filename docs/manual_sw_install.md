# Manual Software Installation

We discuss two approaches

1. manual process
1. remote node setup to (re-)initialize a node. It will config and (re-)install software within the autosetup process.

## Manual Process

A developer may want to install or change software packages. The developer logs into the centralnode. The centralnode knows the ssh auth keys to login on the camnodes.

* [find camnodes using avahi](scanodis.md#scanodis-link-local-discovery) automatically logs ssh services of all camnodes in the network into `log/nodelist.log`
* [find nodes using arp](../src/rns) use `arp_nodelist.sh` (requires sudo priviledges) 

When the developer has ssh'ed into a camnode, she may perform all types of software operations. Similar to ssh, one may use the scp to copy files. 

## rns - remote node setup

Remote node setup (rns) in the [`src/rns`](../src/rns) directory remotely copies the files for the autosetup on a node and re-runs the autosetup process afterwards. This is useful, if there is no `autosetup.zip` file on the node or the developer wants to update the autosetup process. 

**Important premise:** All commands utilize ssh and scp commands behind the scenes. The system where `rns.sh` is started from needs to have ssh login credentials, either by using username/password or key-based authentication. rns will always try to login with username/password first. So, it is required to set the env variable `SSHPASS` to contain the `pi` user password. If username/password login fails, rns will rely on ssh keys properly installed for accessing nodes in the scanner. Latter is true for running rns on the CENTRALNODE to access sshkey-secured camnodes. 

Run `rns.sh` with the following parameters to setup a single node:

```bash
export SSHPASS="raspberry"
rns.sh <node address> <delay> [file directory]
``` 

where 

* `<node address>` IP address of Raspberry Pi node to copy files to
* `<delay>` reboot delay in minutes. Useful, if several nodes shall update, it will distribute the upgrade along differnt times to avoid a peak power consumption of the overall system
* `[file directory]` optionally, provide the directory containing files to copy.  Currently, it supports `autosetup_*.zip` and `booter.sh`. 

rns copies all files into `/boot` directory on the node and re-runs the autosetup through reboot. If the `file directory` is omitted, rns will simply re-run the nodes' autosetup process.

Use [xargs](https://man7.org/linux/man-pages/man1/xargs.1.html) to run `rns.sh` for a list of nodes. 

```bash
cat -b <addr file> | xargs -n2 bash -c './rns.sh $1 $(($0*10)) /some/directory'
```

The `<addr file>` contains one node IP address per line. The `<addr file>` may be the result of running `arp_nodelist.sh`. In the `xargs` command the `$(($0*10))` expression specifies an increasing delay in minutes depending on the line number of the `<addr file>`. As an example, the above expression will expand to the following command sequence.

```bash
./rns.sh 192.168.10.10 10 /some/directory
./rns.sh 192.168.10.11 20 /some/directory
./rns.sh 192.168.10.15 30 /some/directory
./rns.sh 192.168.10.12 40 /some/directory
...
```

If the `<addr file>` is the [scanodis](scanodis.md) nodelist logfile, the command lines for a list of nodes reads 

```
sort -u nodelist.log | cat -b | cut -d$'\t' -f1,3 | xargs -n2 bash -c './rns.sh $1 $(($0*10)) /some/directory'
```

**Note:** One may run `rns` directly from the cloned repository in `/boot/autosetup/3DScanner` as regular user. 
