# User Interface with script-server

[script-server](https://github.com/bugy/script-server) is a Web UI for scripts. 

In the UI provided by the script-server, developers and end-user can run commands to query and control the scanner apparatus.

Access the UI: http://CENTRALNODE/ui

## Scripts and Configuration

Each UI function links to a bash script. script-server runs these scripts through a website. The project stores all scripts in [`src/script-server/scripts`](../src/script-server/scripts). Each script comes with a configuration from [`src/script-server/conf/runners`](../src/script-server/conf/runners)

When the script runs it utilizes the [Test Anything Protocol (TAP)](https://en.wikipedia.org/wiki/Test_Anything_Protocol) for its output. It allows individual tests (TAP producers) to communicate test results in a language-agnostic way. 

All script-server scripts include the a [bash producer](https://github.com/goozbach/bash-tap-functions) for the their TAP output.
 
## Install and Run as Service

script-server only installs on CENTRALNODE. The `install_centralnode.sh` script takes care of downloading the source files from the [script-server's GitHub repo](https://github.com/bugy/script-server). 

The scripts as well as the project specific configuration files are found in `src/script-server`. The install procedure copies them over the source files. At the end of the install procedure it mounts the script-server as user-level systemd service.

The nginx webserver on CENTRALNODE works a reverse proxy and makes the script-server UI available.