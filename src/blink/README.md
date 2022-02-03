# blink

User story
> As a developer I want to visually identify the Raspi nodetype and its operation state, so that I can quickly verify a running setup.

The blink tool controls the raspi's RED led. It enables a developer to visually identify a raspi device by letting it blink. The `nodeblink.sh` script runs blink on a remote node. The node is required to provide a ssh login. 


Relevant scripts:

* `blink.sh` let the RED led blink with a given pattern
* `nodeblink.sh` let a node speficied by its IP address; runs on CENTRALNODE only


Usage (run from CENTRALNODE):

```bash
nodeblink.sh <IP address> <blink pattern>
```

Examples of typical use cases:

Set all known nodes sourced from `nodelist.log` to default blink behavior. Afterwards, let all known nodes blink at a one second interval. 

```bash
nodeblink.sh all 
nodeblink.sh all timer
```

The next example shows an explicit definition of the `nodeblink.sh all timer` command.

```bash
cat /home/pi/log/nodelist.log | sort | uniq | cut -d' ' -f1 | xargs -n 1 -I addr ./nodeblink.sh addr timer
```

