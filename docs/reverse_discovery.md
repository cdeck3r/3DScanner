# Node Reverse discovery

First tests showed that the name resolution across networks does not work. Instead to discover the node of interest, the node to discover calls the discoverer. We refer to this procedure as *reverse node discovery*. 

We discuss two types of approaches:

1. **Current implementation** pastebin alike services 
1. Alternatives: Use of Tracking Services

Implementation of the reverse discovery happens in the [scanodis scripts](scanodis.md).

## pastebin alike Services

[Wiki page on pastebin](https://en.wikipedia.org/wiki/Pastebin)

Currently, we focus on a very simple implementation: The node of interest posts its connection details to a public board. This reveals its identity to the developer, but to the General public as well. We rely on additional measures to secure the node:

* the public board is not known to the public (security by obscurity)
* Firewall between the public network and the node's Network
* Developer gains only Access to the node's Network via VPN
* Node only allows key-based Auth and prohibits user based Auth for Login

There are a few pastebin alike services out there, which allow the creation of a stable document using a URL-only access without user/pass, and furthermore, enable a user to edit / update the document later on. Services we found:

* Ethercalc, https://ethercalc.net/
* rentry.co, https://rentry.co/, *has not been implemented yet*


## Use of Tracking Services

The approach makes the raspi node the active part in the discovery process. 

1. a node accesses a website which contains a tracking service
1. the tracking service logs the access
1. the developer reads the access log to find the IP

Tracking services:

* clicky, https://clicky.com/help/faq/tips/different/noscript 
* loggly, https://documentation.solarwinds.com/en/Success_Center/loggly/Content/admin/tracking-pixel.htm?cshid=loggly_tracking-pixel

Clicky implements strong checks when accessing, e.g. referer, domain names and others. See [clicky FAQ](https://clicky.com/help/faq/tracking/some-visitors) for more details.

loggly has not been tried yet.

