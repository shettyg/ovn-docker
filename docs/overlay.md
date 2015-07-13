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
docker --kv-store="consul:localhost:8500" -d
```

OVN provides network virtualization to containers.  OVN can create
logical networks amongst containers running on multiple hosts.  To better
explain OVN's integration with Docker, this document explains the
end to end workflow with an example.

* Start a IPAM server.

For multi-host networking, you will need an entity that provides consistent
IP and MAC addresses to your container interfaces.  One way to achieve this
is to use a IPAM server that integrates with OVN's Northbound database.
OpenStack Neutron already has an integration with OVN's Northbound database
via a OVN plugin and this document uses it as an example.

Installing OpenStack Neutron with OVN plugin from scratch on a server is out
of scope of this documentation.  Instead this documentation uses a
Docker image that comes pre-packaged with OpenStack Neutron and OVN's daemons
as an example.

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

By default, OVN uses Geneve tunnels for overlay networks.  If you prefer to use
STT tunnels (which are known for high throughput capabilities when TSO is
turned on in your NICs), you can run the following command. (For STT
tunnels to work, you will need a STT kernel module loaded.  STT kernel
module does not come as part of the upstream Linux kernel.)

```
ovn-integrate set-encap-type stt
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
mkdir -p /usr/share/docker/plugins
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
neutron net-create $NID --tenant-id admin --os-url http://$IPAM_IP:9696/ --os-auth-strategy="noauth"
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

[INSTALL.md]:INSTALL.md
