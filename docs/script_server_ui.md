# User Interface with script-server

[script-server](https://github.com/bugy/script-server) is a Web UI for scripts. 


In the UI provided by the script-server, developers and end-user can run commands to query and control the scanner apparatus.

Access the UI: http://CENTRALNODE/ui

## Script Output

TAP


## Install and Run as Service

script-server only installs on CENTRALNODE. The `install_centralnode.sh` script takes care of downloading the source files from the [script-server's GitHub repo](https://github.com/bugy/script-server). 

The scripts as well as the project specific configuration files are found in `src/script-server`. The install procedure copies them over the source files. 


The nginx webserver on CENTRALNODE works a reverse proxy and makes the script-server UI available.