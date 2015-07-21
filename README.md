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

For integration of OVN in the "overlay" mode with Docker's libnetwork, read
[INSTALL.Docker.md]

For backend tools that works independently of Docker's libnetwork, read
[backend.md]

Bugs and Discussions:
---------------------

Once Docker provides the CLI to integrate with libnetwork, we plan to make
the necessary changes to the ovn driver and get the code reviewed and added to
the official Open vSwitch repo. Till then, any questions or discussions can
be had at: discuss@openvswitch.org

[INSTALL.Docker.md]: docs/INSTALL.Docker.md
[backend.md]: docs/backend.md

