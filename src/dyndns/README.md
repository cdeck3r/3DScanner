# Dynamic DNS to Access the Scanner UI

The dynamic DNS approach registers the IP address in a public location for the end-user to access the website UI. Basically, it resembles part of a DNS service, but utilizes the HTTP protocol.

The [documentation](../../docs/dyndns.sh) reports about the details.

Relevant scripts:

* [dyndns.sh](dyndns.sh) The script runs on a public webserver to extract the data from the logfile.
* [setup.sh](setup.sh) Test and run webserver. Installs the cronjob for `dyndns.sh` to run every 5min. 

