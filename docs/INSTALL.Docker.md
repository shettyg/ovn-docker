How to Use Open vSwitch with Docker
====================================

This document describes how to use Open vSwitch with Docker 1.7.0 or
later.  This document assumes that you installed Open vSwitch by following
[INSTALL.md] or by using the distribution packages such as .deb or .rpm.
Consult www.docker.com for instructions on how to install Docker.

Docker 1.7.0 comes with experimental support for multi-host networking.
Integration of Docker networking and Open vSwitch can be achieved via
Open vSwitch virtual network (OVN).


Setup
=====

For multi-host networking with OVN and Docker, Docker has to be started
with a destributed key-value store.  For e.g., if you decide to use consul
as your distributed key-value store, start your Docker daemon with:

```
docker --kv-store="consul:127.0.0.1:8500" -d
```

OVN provides network virtualization to containers.  OVN's integration with
Docker currently works in two modes - the "underlay" mode or the "overlay"
mode.

In the "underlay" mode, OVN requires a OpenStack setup to provide container
networking.  In this mode, one can create logical networks and can have
containers running inside VMs, standalone VMs (without having any containers
running inside them) and physical machines connected to the same logical
network.  This is a multi-tenant, multi-host solution.

In the "overlay" mode, OVN can create a logical network amongst containers
running on multiple hosts.  This is a single-tenant (extendable to
multi-tenants depending on the security characteristics of the workloads),
multi-host solution.  In this mode, you do not need a pre-created OpenStack
setup.

For both the modes to work, a user has to install Open vSwitch in each
VM/host that he plans to run his containers.

The "overlay" mode
==================

* Start a IPAM server.

For multi-host networking, you will need an entity that provides consistent
IP and MAC addresses to your container interfaces.  One way to achieve this
is to use a IPAM server that integrates with OVN's Northbound database.
OpenStack Neutron already has an integration with OVN's Northbound database
via a OVN plugin and this document uses it as an example.

Installing OpenStack Neutron with OVN plugin from scratch on a server is out
of scope of this documentation (though highly recommended).  Instead this
documentation uses a Docker image that comes pre-packaged with OpenStack
Neutron and OVN's daemons as an example.

Start your IPAM server on any host.

```
docker run -d --net=host --name ipam openvswitch/ipam:v2.4.90 /sbin/ipam
```

Once you start your container, you can do a 'docker logs -f ipam' to see
whether the ipam container has started properly.  You should see a log message
of the following form to indicate a successful start.

```
oslo_messaging._drivers.impl_rabbit [-] Connecting to AMQP server on localhost:5672
neutron.wsgi [-] (670) wsgi starting up on http://0.0.0.0:9696/
INFO oslo_messaging._drivers.impl_rabbit [-] Connected to AMQP server on 127.0.0.1:5672
```

Note down the IP address of the host. This document refers to this IP address
in the remainder of the document as $IPAM_IP.

* One time setup.

On each host, where you plan to spawn your containers, you will need to
set the IPAM server's IP address.

```
ovn-integrate set-ipam $IPAM_IP
```

You will also need to provide the local IP address via which other hosts
can reach this host. This IP address is referred as the local tunnel endpoint.

```
ovn-integrate set-tep $LOCAL_IP
```

And finally, start the OVN controller.

```
ovn-controller --pidfile --detach -vconsole:off --log-file
```

* Start the Open vSwitch network driver.

By default Docker uses Linux bridge for networking.  But it has support
for external drivers.  To use Open vSwitch instead of the Linux bridge,
you will need to start the Open vSwitch driver.

The Open vSwitch driver uses the Python's flask module to listen to
Docker's networking api calls.  The driver also uses OpenStack's
python-neutronclient libraries.  So, if your host does not have Python's
flask module or python-neutronclient install them with:

```
easy_install -U pip
pip install python-neutronclient
pip install Flask
```

Start the Open vSwitch driver on every host where you plan to create your
containers.

```
mkdir -p /etc/docker/plugins
ovn-docker-driver --overlay-mode --detach
```

Docker has inbuilt primitives that closely match OVN's logical switches
and logical port concepts.  Please consult Docker's documentation for
all the possible commands.  Here are some examples.

* Create your logical switch.

To create a logical switch with name 'foo', run:

```
NID=`docker network create -d openvswitch foo`
```

Since Docker currently does not provide the ability to provide the
subnet information for your networks, you will need to associate
that information manually, via:

```
neutron subnet-create $NID 192.168.1.0/24 --tenant-id admin --os-url http://$IPAM_IP:9696/ --os-auth-strategy="noauth"
```

* List your logical switches.

```
docker network ls
```

* Create your logical port.

To create a logical port with name 'db' in the network 'foo', run:

```
docker service publish db.foo
```

* List all your logical ports.

```
docker service ls
```

* Attach your logical port to a container.

```
docker service attach CONTAINER_ID db.foo
```

* Detach your logical port from a container.

```
docker service detach CONTAINER_ID db.foo
```

Delete your logical port.

```
docker service unpublish db.foo
```

* Running commands directly on the IPAM server (bypassing Docker)

Since the above examples shows integration with a OpenStack Neutron
IPAM server, one can directlty invoke 'neutron' commands to fetch
information about logical switches and ports. e.g:

```
export OS_URL="http://$IPAM_IP:9696/"
export OS_AUTH_STRATEGY="noauth"
neutron net-list
```

The "underlay" mode
===================

This mode requires that you have a OpenStack setup pre-installed with OVN
providing the underlay networking.

* One time setup.

A OpenStack tenant creates a VM with a single network interface that belongs
to a management logical network.  The tenant needs to fetch the port-id
associated with the spawned VM.  This can be obtained by running a
'nova list' to fetch the 'id' associated with the VM and then by running
the command 'neutron port-list --device_id=$id'.

Inside the VM, download the OpenStack RC file that contains the tenant
information (henceforth referred to as 'openrc.sh').  Edit the file and add the
previously obtained port-id information to the file by appending the following
line: export OS_VIF_ID=$id.  After this edit, the file will look something
like:

```
#!/bin/bash
export OS_AUTH_URL=http://10.33.75.122:5000/v2.0
export OS_TENANT_ID=fab106b215d943c3bad519492278443d
export OS_TENANT_NAME="demo"
export OS_USERNAME="demo"
export OS_VIF_ID=e798c371-85f4-4f2d-ad65-d09dd1d3c1c9
```

* Create the Open vSwitch bridge.

Your VM will have one ethernet interface (e.g.: 'eth0').  You will need to add
that device as a port to an Open vSwitch bridge and move its IP address and
route related information to that bridge.  For example, assuming that your
device is 'eth0', you could run:

```
ovn-integrate nics-to-bridge eth0
```

The above command will move the IP address and route information of 'eth0'
to 'breth0'.

If you use DHCP to obtain an IP address, then you should kill the DHCP client
that was listening on the physical Ethernet interface (e.g. eth0) and start
one listening on the Open vSwitch bridge (e.g. breth0).

Depending on your VM, you can make the above step persistent across reboots.
For e.g.:, if your VM is Debian/Ubuntu, you can read
[openvswitch-switch.README.Debian]


* Start the Open vSwitch network driver.

Source the openrc file. e.g.:

````
source openrc.sh
```

Start the network driver.

```
ovn-docker-driver --underlay-mode --bridge breth0 --detach
```

From here-on you can use the same Docker commands as described in the
section 'The "overlay" mode'.

[INSTALL.md]: INSTALL.md
[openvswitch-switch.README.Debian]: debian/openvswitch-switch.README.Debian
