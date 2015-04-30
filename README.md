Integration of OVN with Docker Containers.
-----------------------------------------

This document described how to use OVN (Open vSwitch virtual network) with
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
solution.

For both the modes to work, a user has to install Open vSwitch in each VM/host
that he plans to run his containers.

Installing Open vSwitch for OVN
-------------------------------
TBA

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

* Create a logical network and provide the subnet from which
the IP address is assigned to that network. If a network has already
been created via Neutron, you can skip this step.

```
ovn-container net-create ls0 192.168.1.0/24
```

The above command returns a uuid for that nework.

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

* Create a network container to setup networking with the uuid of the
endpoint passed as the argument to '--network'. You can add multiple
endpoints to the container by repeating the '--network' command.

```
ovn-container container-create --network=88bb5dd3-2da9-40e2-9b75-a0406980301c
```

The above command returns back the created network container id.

* Start your main container and ask it to attach to the just created
network container.

```
docker run -d --net=container:db0b1ee8227356358f095021a35b6509c8787720473fe7c8a015dfe15460e65c  ubuntu /bin/sh -c "while true; do echo hello world; sleep 1; done"
```

This returns the container id.

* You can check the created container interface, its IP address and MAC address
by execing into the container. e.g.:

```
docker exec -it c03e4bd51b0a0b9e39512cda5cbd7c1602c33e2ad2d0c00632250c8caad1b4f2 bash
```

* After you stop your container, you can delete the created endpoint with:

```
ovn-container endpoint-delete 88bb5dd3-2da9-40e2-9b75-a0406980301c
```

While deleting the endpoint, if it is noticed that the previously created
network container does not have any endpoints associated with it anymore,
it is deleted automatically.

* If you do not have a need for the created network, you can delete it with:

```
ovn-container net-delete ls0
```

Running OVN in the overlay mode
-------------------------------

To better understand OVN's integration with containers in the "overlay"
mode, this document explains the end to end workflow with an example.

* Start a IPAM container on any host. This container is responsible to
provide IP address and MAC address for your containers.

```
docker run -d --net=host --name ipam ovntest/ipam:v0.1
```

Note down the IP address of the host. This document referes to this IP address
in the remainder of the document as $IPAM_IP.

* On each host, where you plan to spawn your containers, you will need to
create an Open vSwitch integration bridge.

```
ovn-integrate create-integration-bridge
```

* Initialize OVN for the VM in question.

```
ovn-container init --bridge br-int --overlay-mode
```

* You will have to set a couple of environment variables.
export OS_AUTH_STRATEGY="noauth"
export OS_URL="http://$IPAM_IP:9696/"

* From here-on the workflow is the same as that for the "underlay" mode
(as described in the section "Running OVN in the underlay mode"). You
can use the "net-create", "net-list", "net-delete", "endpoint-create",
"endpoint-delete", "container-create" commands.
