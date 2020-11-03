# SSHkey Distribution to Secure Access to the Nodes

The access to the Raspberry Pi nodes, camnode and centralnode, is secured using ssh keys. User / password access is prohibited. The [autosetup scripts](autosetup_scripts.md) deploy the ssh keys on the respective nodes. The following UML diagram display where each key is deployed after the dev system has created the autosetup archives. 

![SSH key distributed across Raspberry Pi](http://www.plantuml.com/plantuml/png/3Ssn4S8m30NGFbF00b6HZYe56p00PoGTpiMMSzBN0TkJwfLl3HH7zZPTD-EMekdjKe4ZRaHUFlDxGyrNXZeFWnfc7frObFV5QRa_k9YfKo-14naS9CSpekxwYnbVJAkQdCKV)

While the autosetup archives are given to end-user for the [setup of the Raspberry Pi nodes](raspi_setup_process.md), the centralnode's private key is not part of the archives. In the case, the end-user accidentially leaks the key from the autosetup archives, the centralnode's private key remains protected on the dev system by the developer.

Furthermore, the diagram indicates ssh login relations between the nodes. The design restricts the login as follows:  

* dev system can ssh into the centralnode
* centralnode can ssh into each camnode

As a result, the centralnode works as a jump server to access the camnodes. This design enables automatic process control of the camnodes from the centralnode and secures the networked access to the camnodes' private key stored on the centralnode.


