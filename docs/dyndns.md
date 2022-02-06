# Dynamic DNS to Access the Scanner UI

The end-user controls the scanner using a webbrowser. The UI's website is provided by the centralnode. If  this system is rebooted, it renews a the DHCP release and may request a new IP address.

**Problem**

The centralnode does not register the IP in the DNS. As a consequence, the end-user must know the centralnode's IP address to access the UI. After the renewval of the DHCP lease, the user may no longer access the UI's website.

**Approach**

The dynamic DNS approach registers the IP address in a public location for the end-user to access the website UI. Basically, it resembles part of a DNS service, but utilizes the HTTP protocol. The sequence diagram below depicts the details of approach.

![Sequence diagram for DynDNS approach](http://www.plantuml.com/plantuml/png/3SMn4G8W30NGLNG1Kj1Pku43U9ZaX1E29Z-dRg-lUSTXF5CqVHuwy8mJaRTtkG_ql6MeypQeeV1UnAByg4xrVE5cfawh1Vx9vg3GrrM-9XO57_m0)


At first, the [`scanodis.sh`](scanodis.md) script periodically accesses a public webserver from the scanner's IP address. The logfile contains this originating IP address. A cronjob runs every 5min to parse the logfile and extract the IP. Finally, it writes an `index.html` containing a link with the IP and accessible through the public webserver for the end-user. 

The `index.html` contains a refresh meta tag, which loads the scanner's website UI. Additionally, a domain forwarding server or short URL service can be utilized to define a descriptive URL which calls the public webserver. 

**Network**

The firewall on the public webserver restricts the access to the centralnode subnet only; for the IP registration as well as for the query. We assume the end-user resides in the centralnode subnet. As a consequence, the dyndns approach only works from the scanner network. The following UML diagram depicts the situation.

![Component diagram for DynDNS network](http://www.plantuml.com/plantuml/png/3SMn3S9030NGLM21Sv6EcWqO83fiYqGa_oBxMy3sv3NlkaAtCg_OBWjvv4qa-gUzLYxrhFJG0JhOTEoYvlgUGgRxGplW8NjFdjdG53rc-y6GCvoDN_u1)

