# Customize RasPiOS Image

We need to customize the RasPiOS image in order to enable our own toolchain. The objective is to have an tailored image which can be easily replicated to all Raspberry Pis. This image will enable automatation and infrastructure support for all software functions.

## Design Concept

While the image creation process is left to the developer, the end-user shall setup the Raspberry Pis for a concrete scanner and the customization to its operation environment. The end-user shall conduct all manual steps to setup the Raspberry Pis without the need of a developer to be present. 

The design concept of the image follows a layered approach. We take a base RasPiOS image and enable it to update itself using the easily accessible `/boot` partition. The end-user adds the node-specific autosetup scripts into this partition effectively creating the Scanner RaspiOS image. The following diagram depicts the layered RasPiOS design.

![RaspiOS Stack](http://www.plantuml.com/plantuml/png/3SMn3G8n30NGLM21kBYEcWqO08KVYukuE97zBHYVUysxTiEHJTEFoqwkk8bu_PPtvvwl37LCeneBvX0qnMTpsUuFL3Dr6JLurYP2i9vUO_KPXJ_-0G00)

## Before we start

The dev system docker container must run in *priviledge* mode for the instructions to work. Spin up the container with the variable `DEVSYS_PRIV` set and get a shell from the container

```bash
export DEVSYS_PRIV=true
docker-compose up -d 3dsdev
docker exec -it 3dsdev /bin/bash
```

**Note:** In the priviledge mode, the container has root access to the host system. Unset the variable once you have created the image.

## Retrieve Default RasPiOS Image

Download the default RasPiOS image. Please use the download script for reproducibility.

```bash
$ scripts/raspios_download.sh
```

The script downloads `2020-08-20-raspios-buster-armhf-lite.zip` und unzips it in the `raspios` folder. Change into this folder and create device maps from the the image's partition tables. 

```bash
$ kpartx -v -a 2020-08-20-raspios-buster-armhf-lite.img
add map loop0p1 (253:0): 0 524288 linear 7:1 8192
add map loop0p2 (253:1): 0 3072000 linear 7:1 532480

$ ls /dev/mapper
total 0
crw------- 1 root root  10, 236 Oct 18 11:35 control
brw-rw---- 1 root root 253,   0 Oct 18 11:56 loop0p1
brw-rw---- 1 root root 253,   1 Oct 18 11:56 loop0p2
```

The listing displays the root filesystem at the second position mapped to `/dev/mapper/loop0p2`, which serves as mountpoint in the next command.

```bash
$ mount /dev/mapper/loop0p2  /mnt
```

It mounts the RasPiOS root filesystem in rw mode. Now, you can customize the filesystem. All changes will persist. 


## Enable Toolchain

Once the image runs on the Raspberry Pi, we still want to update software and relevant information to customize the behavior. 
*tbd*

## Finalize Image

Finally, unmount and remove the filesystem.

```bash
$ unmount /mnt
$ kpartx -d /dev/loop0
```

The file `2020-08-20-raspios-buster-armhf-lite.img` is now the project specific RasPiOS image. 