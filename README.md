# 3DScanner

This project develops software for a person-sized, full body DIY Raspberry Pi based 3D Scanner. The scanner stands at the [Textile Faculty of the Reutlingen University](https://www.td.reutlingen-university.de/en/startseite-englisch/). There, [Katerina Rose](https://www.td.reutlingen-university.de/fakultaet/ansprechpartner/lehre/#Katerina-Rose) researches novel approaches for digitization in the textil industry including textile technology and sewing pattern using CAD. The scanner is an enabling technology and an instrument a for her research. 

I support Katerina on the embedded software part for the scanner. This software controls the distributed camera system.

Investigators:

* [Katerina Rose](https://www.td.reutlingen-university.de/fakultaet/ansprechpartner/lehre/#Katerina-Rose)
* [Christian Decker](cdeck3r.com)

Ressources:

* [Trello board](https://trello.com/b/CqnWyFS4) to organize dev tasks

## Project Information

The project builds on the instructions from a [previous project](https://www.instructables.com/Multiple-Raspberry-PI-3D-Scanner/). There are several similar DIY projects of this type available on the Internet. Commercial products exist as well. 

The DIY project uses COTS available Raspberry Pis embedded computers to implement a distributed camera system. The available documentation is limited and the setup and software operation of the camera hardware require substantial software skills.

However, researchers in this project are not software experts. The goals of this project are therefore

* enable non-software experts to reproduce the software setup of the scanner 
* understanding of the scanner's software operation state for a successful application use

## Technical Approach

From a computer science perspective the project proposes a couple distributed system challenges. Since all software runs distributed on approx. 50 Raspberry Pi computers, a primary activity focuses on infrastructure support. Each software change applies to 50 Raspberry Pis. Automation of deployment is crucial. Some fundamental functions to support are 

* Automate deployment of software directly from github
* Common, but secure access to Raspberry Pis
* Distributed control 
* Debugging and maintenance support

In all cases, we want to keep the end-use in mind and at the center of our development efforts.

## Dev System

We setup a docker image to support the development on a desktop computer. It helps us to reproduce script operations on the Raspberry Pi. The dev system bases on the Debian Buster distro. The motivation is that [Raspberry Pi OS](https://en.wikipedia.org/wiki/Raspberry_Pi_OS) bases on the same one. At the current date the version is:
```bash
$ uname -a
Linux ec72378ae28c 4.19.76-linuxkit #1 SMP Tue May 26 11:42:35 UTC 2020 x86_64 GNU/Linux
```

**Setup:** Start in project's root dir and create a `.env` file with the content shown below.
```
# .env file

# In the container, this is the directory where the code is found
# Example:
APP_ROOT=/3DScanner

# the HOST directory containing directories to be mounted into containers
# Example:
VOL_DIR=/dev/3DScanner
```

**Create** docker image. Please see [Dockerfiles/Dockerfile.3dsdev](https://github.com/cdeck3r/3DScanner/blob/master/Dockerfiles/Dockerfile.3dsdev) for details.
```bash
docker-compose build 3dsdev 
```

**Spin up** the container and get a shell from the container
```bash
docker-compose up -d 3dsdev
docker exec -it 3dsdev /bin/bash
```

## License

Information provided in the [LICENSE](LICENSE) file.
