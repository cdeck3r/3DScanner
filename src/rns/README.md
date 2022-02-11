# rns - Remote Node Setup

User story
> As a developer, I want to setup the node remotely, either from the centralnode or the dev system. 

rns remotely copies the files for the autosetup on a node and re-runs the autosetup process afterwards. This is useful, if there is no autosetup.zip file on the node or the developer wants to update the autosetup process. 

The node is required to provide a ssh login. 

References to project documentation 

* [remote node setup](../../docs/README.md#software-update-process)
* [automatic node setup](../../docs/autosetup.md)

Relevant scripts:

* `rns.sh` runs a remote node setup for a single node 
* `arp_nodelist.sh` performs a [arp-scan](https://linux.die.net/man/1/arp-scan) for Raspberry Pi nodes and outputs them as a list of IP addresses. Note: script must run under `sudo`.

**Important premise:** rns utilize ssh and scp commands behind the scenes. The system where `rns.sh` is started from needs to have ssh login credentials, either by using username/password or key-based authentication. rns will always try to login with username/password first. So, it is required to set the env variable `SSHPASS` to contain the `pi` user password. If username/password login fails, rns will rely on ssh keys properly installed for accessing nodes in the scanner. Latter is true for running rns on the CENTRALNODE to access sshkey-secured camnodes. 

Setup a single camnode (run from centralnode)

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

If the `<addr file>` is the [scanodis](../scanodis) nodelist logfile, the command lines for a list of nodes reads 

```
sort -u nodelist.log | cat -b | cut -d$'\t' -f1,3 | xargs -n2 bash -c './rns.sh $1 $(($0*10)) /some/directory'
```

**Note:** One may run `rns` directly from the cloned repository in `/boot/autosetup/3DScanner` as regular user. 