Docker drivers for OVN are now part of the Open vSwitch repository. So
you don't need to look at this repository for Docker and OVN related things.

Please read https://github.com/openvswitch/ovs/blob/master/INSTALL.Docker.md
for all the details.

Integration of OVN with Docker Containers.
-----------------------------------------

OVN provides network virtualization to containers.  OVN's integration with
containers works in two modes - the "underlay" mode or the "overlay" mode.

In the "underlay" mode, OVN requires a OpenStack setup to provide container
networking. In this mode, one can create logical networks and can have
containers running inside VMs, VMs and physical machines connected to the
same logical network.  This is a multi-tenant, multi-host solution.

In the "overlay" mode, OVN can create a logical network amongst containers
running on multiple hosts. This is a single-tenant (extendable to multi-tenants
depending on the security characteristics of the workloads), multi-host
solution. In this mode, you do not need a pre-created OpenStack setup.

For both the modes to work, a user has to install Open vSwitch in each VM/host
that he plans to run his containers.

For integration of OVN with Docker's libnetwork, read [INSTALL.Docker.md]

[INSTALL.Docker.md]: docs/INSTALL.Docker.md

