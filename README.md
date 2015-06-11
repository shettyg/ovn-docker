Integration of OVN with Docker Containers.
-----------------------------------------

This document describes how to use OVN (Open vSwitch virtual network) with
Docker containers.  This document assumes that you installed Docker
by consulting www.docker.com for instructions.

Setup
-----

OVN provides network virtualization to containers.  OVN's integration with
containers works in two modes - the "underlay" mode or the "overlay" mode.

In the "underlay" mode, OVN requires a OpenStack setup to provide container
networking. In this mode, one can create logical networks and can have
containers, VMs and physical machines connected to the same logical network.
This is a multi-tenant, multi-host solution.

In the "overlay" mode, OVN can create a logical network amongst containers
running on multiple hosts. This is a single-tenant (extendable to multi-tenants
depending on the security characteristics of the workloads), multi-host
solution. In this mode, you do not need a pre-created OpenStack setup.

For both the modes to work, a user has to install Open vSwitch in each VM/host
that he plans to run his containers.

Installing Open vSwitch for OVN
-------------------------------
OVN is currently in development mode and as such there is no released packages
available for direct installation. The installed ipam (described later) and the
ovn-controller should be based off the same code base. You can install it from
source using the mentioned commit below. For e.g., on a Ubuntu 14.04 system,
you can install it with:

```
sudo apt-get install -y autoconf libtool sparse openssl pkg-config make gcc libssl-dev git
git clone https://github.com/openvswitch/ovs.git
cd ovs
git checkout -b ovn_local 767944131928487497579fd48
./boot.sh
./configure --prefix=/usr --localstatedir=/var  --sysconfdir=/etc --enable-ssl --with-linux=/lib/modules/`uname -r`/build
make -j3 
make install
cp debian/openvswitch-switch.init /etc/init.d/openvswitch-switch
insmod ./datapath/linux/openvswitch.ko
insmod ./datapath/linux/vport-geneve.ko
/etc/init.d/openvswitch-switch start
```

Installing Neutron client for OVN
---------------------------------
OVN integration with containers uses OpenStack network APIs. On each host where
you plan to run your containers, install python-neutronclient. For e.g., on
a Ubuntu 14.04 system, you can install it from source with:

```
git clone https://github.com/openstack/python-neutronclient.git
cd python-neutronclient
easy_install -U pip
apt-get install python-dev
pip install -r requirements.txt
python setup.py install
```

Running OVN in the overlay mode
-------------------------------

To better understand OVN's integration with containers in the "overlay"
mode, this document explains the end to end workflow with an example.
(The examples here have been run on a Ubuntu 14.04 machines.)

* Start a IPAM container on a separate host. This container is responsible to
provide IP address and MAC address for your containers and acts as
a central point for your OVN system.
(The ipam is actually a containerized OpenStack Neutron, with OVN plugin
and daemons.  So the same apis that work for OpenStack Neutron, work here too.
The container runs mysql, rabbitmq and OVS daemons. Since the command
below asks you to run the container with '--net=host', it is ideal
if you do not have mysql, rabbitmq and OVS daemons running in the
host already.)

```
docker run -d --net=host --name ipam ovntest/ipam:v0.19 /sbin/ipam
```

Once you start your container, you can do a 'docker logs -f ipam' to see
whether the ipam container has started properly. You should see a log
message of the following form to indicate a successfull start.

```
oslo_messaging._drivers.impl_rabbit [-] Connecting to AMQP server on localhost:5672
neutron.wsgi [-] (670) wsgi starting up on http://0.0.0.0:9696/
INFO oslo_messaging._drivers.impl_rabbit [-] Connected to AMQP server on 127.0.0.1:5672
```

Note down the IP address of the host. This document referes to this IP address
in the remainder of the document as $IPAM_IP.

* On each host, where you plan to spawn your containers, you will need to
create an Open vSwitch integration bridge.

```
ovn-integrate create-integration-bridge
```

You will also need to set the IPAM server's IP address

```
ovn-integrate set-ipam $IPAM_IP
```

You will also need to provide the local IP address
via which other hosts can reach this host. This IP address
is referred as the local tunnel endpoint.

```
ovn-integrate set-tep $LOCAL_IP
```

By default, OVN uses Geneve tunnels for overlay. If you prefer to
use STT tunnels (which are known for high throughput capabilities when
TSO is turned on in your NICs), you can run the following command.

```
ovn-integrate set-encap-type stt
```

And finally, start the ovn-controller.
```
ovn-controller --pidfile --detach -vconsole:off --log-file
```

* Initialize OVN for the VM in question.

```
ovn-container init --bridge br-int --overlay-mode
```

* Create a logical network and provide the subnet from which
the IP address is assigned to that network.

```
ovn-container net-create ls0 192.168.1.0/24
```

The above command returns a uuid for that network.

* View all the available networks.

```
ovn-container net-list
```

* Create a port (or endpoint) in the network 'ls0', with an optional port name
'ls0p0'

```
ovn-container endpoint-create ls0 ls0p0
```

The above command returns a uuid for that port. Internally it assigns
an IP address and mac address for that port.

* View all the created endpoints.

```
ovn-container endpoint-list
```

* Create a network container to setup networking with the uuid(or name) of the
endpoint passed as the argument to '--network'. You can add multiple
endpoints to the container by repeating the '--network' command.

```
ovn-container container-create --network=ls0p0
```

The above command returns back the created network container id, referred in
the next step as $NETWORK_CONTAINER.

* Start your main container and ask it to attach to the just created
network container. e.g.:

```
docker run -d --net=container:$NETWORK_CONTAINER  ubuntu /bin/sh -c "while true; do echo hello world; sleep 1; done"
```

The above command returns back the CONTAINER_ID. You can enter the container
to look at the assigned IP and MAC addresses. You can also do any ping tests to
check network connectivity. To enter the container, run:

```
docker exec -it $CONTAINER_ID bash
```

* After you stop your container, you can delete the created endpoint with:

```
ovn-container endpoint-delete ls0p0
```

While deleting the endpoint, if it is noticed that the previously created
network container does not have any endpoints associated with it anymore,
it is deleted automatically.

* If you do not have a need for the created network, you can delete it with:

```
ovn-container net-delete ls0
```

Running OVN in the underlay mode
--------------------------------

To better understand OVN's integration with containers in the "underlay"
mode, this document explains the end to end workflow with an example. This
document assumes that the user is familiar with OpenStack.

* A OpenStack tenant creates a VM with a single network interface that
belongs to a management logical network.  The VM is meant to host containers.

* The OpenStack tenant needs to fetch the port-id associated with the
spawned VM. This can be obtained by running a 'nova list' to fetch the
'id' associated with the VM and then by running the command
'neutron port-list --device_id=$id'

* Inside the VM, download the OpenStack RC file that contains the tenant
information. Edit the file and add the previously obtained port-id information
to the file by appending the following line.
export OS_VIF_ID=$id

Now, source the file: e.g:
source username-openrc.sh

* Your VM will have one ethernet interface (e.g.: 'eth0'). You will need to
add that device as a port to an Open vSwitch bridge and move its IP address
and route related information to that bridge. For example, assuming that
your device is 'eth0, you could run:

```
ovn-integrate nics-to-bridge eth0
```

The above command will move the IP address and route information of 'eth0'
to 'breth0'.

If you use DHCP to obtain an IP address, then you should kill the
DHCP client that was listening on the physical Ethernet interface
(e.g. eth0) and start one listening on the Open vSwitch bridge
(e.g. breth0).

* Initialize OVN for the VM in question.

```
ovn-container init --bridge breth0 --underlay-mode
```

* From here-on the workflow is the same as that for the "overlay" mode
(as described in the section "Running OVN in the overlay mode"). You
can use the "net-create", "net-list", "net-delete", "endpoint-create",
"endpoint-delete", "container-create" commands.

Bugs and Discussions:
---------------------

Once Docker provides the CLI to integrate with libnetwork, we plan to make
the necessary changes to the ovn driver and get the code reviewed and added to
the official Open vSwitch repo. Till then, any questions or discussions can
be had at: discuss@openvswitch.org

