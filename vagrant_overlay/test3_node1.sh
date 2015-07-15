# Multi-host node1

IPAM_IP=`sudo ovs-vsctl get Open-vSwitch . external_ids:ipam | sed 's/"//g'`

# Create network foo

NID=`docker network create -d openvswitch foo`
neutron net-create $NID --tenant-id admin --os-url http://$IPAM_IP:9696/ --os-auth-strategy="noauth"
neutron subnet-create $NID 192.168.1.0/24 --tenant-id admin --os-url http://$IPAM_IP:9696/ --os-auth-strategy="noauth"

if docker network ls | grep foo 2>&1 >/dev/null; then :; else
  echo "test failed with no network seen"
  exit 1
fi


# Create and attach service at same time

docker run -itd --publish-service app.foo --name postgres postgres

SID=`docker service ls --no-trunc | grep app | awk '{print $1}'`
port_name=`echo $SID | cut -c 1-15`

if neutron port-show $SID --tenant-id admin --os-url http://$IPAM_IP:9696/ --os-auth-strategy="noauth"  > /dev/null 2>&1 ; then : ; else
  echo "test failed with no neutron port created"
  exit 1
fi

if ovs-vsctl list interface $port_name > /dev/null 2>&1; then : ; else
  echo "test failed with no OVS port created while service attach"
  exit 1
fi

if docker exec -it postgres ip addr show eth0 | grep 192.168.1.2/24 > /dev/null 2>&1; then : ; else
  echo "test failed with no interface seen inside container"
  exit 1
fi
