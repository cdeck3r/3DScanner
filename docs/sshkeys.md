# SSH Keys distributed across Raspberry Pi

The access to the Raspberry Pi nodes, camnode and centralnode, is secured using ssh keys. User / password access is prohibited. The autosetup scripts deploy the ssh keys on the respective nodes. The following UML diagram display where each key is deployed after the dev system has created the autosetup archives.

Furthermore, the diagram indicates ssh login relations between the nodes. The design restricts the login as follows:  

* dev system can ssh into the centralnode
* centralnode can ssh into each camnode

As a result, the centralnode works as a jump server to access the camnodes. This design enables updates from the centralnode and secures the access to the camnodes' private key through the network on the centralnode.

![SSH key distributed across Raspberry Pi](http://www.plantuml.com/plantuml/png/3Ssn4S8m30NGFbF00b6HZYe56p00PoGTpiMMSzBN0TkJwfLl3HH7zZPTD-EMekdjKe4ZRaHUFlDxGyrNXZeFWnfc7frObFV5QRa_k9YfKo-14naS9CSpekxwYnbVJAkQdCKV)
