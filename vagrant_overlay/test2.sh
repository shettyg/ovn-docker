# Create a network, create a service, attach it, detach it, delete it etc

IPAM_IP=`sudo ovs-vsctl get Open-vSwitch . external_ids:ipam | sed 's/"//g'`

# Create network foo

NID=`docker network create -d openvswitch foo`
neutron subnet-create $NID 192.168.1.0/24 --tenant-id admin --os-url http://$IPAM_IP:9696/ --os-auth-strategy="noauth"

if docker network ls | grep foo 2>&1 >/dev/null; then :; else
  echo "test failed with no network seen"
  exit 1
fi


# Start a container
docker run -itd  --name postgres postgres


# Create a service
SID=`docker service publish my-service.foo`

if docker service ls | grep my-service >/dev/null 2>&1; then :; else
  echo "test failed with no service seen"
  exit 1
fi

if neutron port-show $SID --tenant-id admin --os-url http://$IPAM_IP:9696/ --os-auth-strategy="noauth"  > /dev/null 2>&1 ; then : ; else
  echo "test failed with no neutron port created"
  exit 1
fi

# Attach the service
docker service attach postgres my-service.foo

port_name=`echo $SID | cut -c 1-15`

if ovs-vsctl list interface $port_name > /dev/null 2>&1; then : ; else
  echo "test failed with no OVS port created while service attach"
  exit 1
fi

if docker exec -it postgres ip addr show eth1 | grep 192.168.1.2/24 > /dev/null 2>&1; then : ; else
  echo "test failed with no interface seen inside container"
  exit 1
fi

# Detach service
docker service detach postgres my-service.foo

if ovs-vsctl list interface $port_name  > /dev/null 2>&1; then
  echo "test failed with OVS port still exists while service detach"
  exit 1
fi

# Delete service

docker service unpublish my-service.foo

if neutron port-show $SID --tenant-id admin --os-url http://$IPAM_IP:9696/ --os-auth-strategy="noauth" > /dev/null 2>&1 ; then
  echo "test failed with neutron port still exists"
  exit 1
fi

# Create and attach service at same time

docker run -itd --publish-service db.foo --name postgres1 postgres

SID=`docker service ls --no-trunc | grep foo | awk '{print $1}'`
port_name=`echo $SID | cut -c 1-15`

if neutron port-show $SID --tenant-id admin --os-url http://$IPAM_IP:9696/ --os-auth-strategy="noauth"  > /dev/null 2>&1 ; then : ; else
  echo "test failed with no neutron port created"
  exit 1
fi

if ovs-vsctl list interface $port_name > /dev/null 2>&1; then : ; else
  echo "test failed with no OVS port created while service attach"
  exit 1
fi

if docker exec -it postgres1 ip addr show eth0 | grep 192.168.1.3/24 > /dev/null 2>&1; then : ; else
  echo "test failed with no interface seen inside container"
  exit 1
fi

# Stop and delete container
docker stop postgres1
docker rm postgres1

# Delete service
docker service unpublish db.foo

if neutron port-show $SID --tenant-id admin --os-url http://$IPAM_IP:9696/ --os-auth-strategy="noauth" > /dev/null 2>&1 ; then
  echo "test failed with neutron port still exists"
  exit 1
fi

# Delete network

docker network rm foo

if docker network ls | grep foo 2>&1 >/dev/null; then
  echo "test failed with no network seen"
  exit 1
fi

if neutron net-show $NID --tenant-id admin --os-url http://$IPAM_IP:9696/ --os-auth-strategy="noauth" 2>/dev/null; then
  echo "test failed with neutron networt not deleted"
  exit 1
fi

# Delete container

docker stop postgres
docker rm postgres

