# Customize RaspiOS Image

We need to customize the RaspiOS image in order to enable our own toolchain. The objective is to have an tailored image which can be easily replicated to all Raspberry Pis. This image will enable automatation and infrastructure support for all software functions.

## Design Concept

While the image creation process is left to the developer, the end-user shall setup the Raspberry Pis for a concrete scanner and the customization to its operation environment. The end-user shall conduct all manual steps to setup the Raspberry Pis without the need of a developer to be present. 

The design concept of the image follows a layered approach. We take a base RaspiOS image and enable it to update itself using the easily accessible `/boot` partition. The end-user adds the node-specific autosetup scripts into this partition effectively creating the Scanner RaspiOS image. The following diagram depicts the layered RaspiOS design.

![RaspiOS Stack](http://www.plantuml.com/plantuml/png/3SMn3G8n30NGLM21kBYEcWqO08KVYukuE97zBHYVUysxTiEHJTEFoqwkk8bu_PPtvvwl37LCeneBvX0qnMTpsUuFL3Dr6JLurYP2i9vUO_KPXJ_-0G00)

## Before we start

The dev system docker container must run in *priviledge* mode for the instructions to work. Spin up the container with the variable `DEVSYS_PRIV` set and get a shell from the container

```bash
export DEVSYS_PRIV=true
docker-compose up -d 3dsdev
docker exec -it 3dsdev /bin/bash
```

**Note:** In the priviledge mode, the container has root access to the host system. Unset the variable once you have created the image.

## Quickstart

The following script mounts the given RaspiOS image on `/mnt`. It installs the `booter.sh` script and creates the service in the RaspiOS filesystem. Finally, it unmounts the image. 

```bash
src/raspios_setup/raspios_customize.sh <path/to/raspios.img>
```

If you do not provide the image as parameter, the `raspios_customize.sh` expects the RaspiOS image already mounted on `/mnt`. We describe the step-by-step instructions in the following sections.

## Default RaspiOS

Download the default RaspiOS image. Please use the download script for reproducibility.

```bash
$ src/raspios_setup/raspios_download.sh
```

The script downloads `2020-08-20-raspios-buster-armhf-lite.zip` und unzips it in the `raspios` directory in the project root. Change into this directory and create device maps from the the image's partition tables. 

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
$ mount /dev/mapper/loop0p1  /mnt/boot
```

It mounts the RaspiOS root filesystem as well as the FAT boot partition in rw mode. Now, you can customize the filesystem. All changes will persist. 


## Customize RaspiOS

Once the image runs on the Raspberry Pi, we still want to update software and relevant information to customize the behavior. The systemd process shall run our `booter.sh` script. **Note:** The term [*booter*](https://en.wikipedia.org/wiki/Booter) refers to process where software loaded without the help of other actors.

The following script installs `booter.sh` and creates the service in the RaspiOS filesystem on `/mnt` by default.

```bash
src/raspios_setup/raspios_customize.sh
```

## Finalize Image

Finally, unmount and remove the filesystem.

```bash
$ umount /mnt/boot
$ umount /mnt
$ kpartx -d /dev/loop0
```

The file `2020-08-20-raspios-buster-armhf-lite.img` is now the project specific RaspiOS image. 
