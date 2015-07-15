# Create and attach service at same time

IPAM_IP=`sudo ovs-vsctl get Open-vSwitch . external_ids:ipam | sed 's/"//g'`

docker run -itd --publish-service mydb.foo --name postgres postgres

SID=`docker service ls --no-trunc | grep mydb | awk '{print $1}'`
port_name=`echo $SID | cut -c 1-15`

if neutron port-show $SID --tenant-id admin --os-url http://$IPAM_IP:9696/ --os-auth-strategy="noauth"  > /dev/null 2>&1 ; then : ; else
  echo "test failed with no neutron port created"
  exit 1
fi

if ovs-vsctl list interface $port_name > /dev/null 2>&1; then : ; else
  echo "test failed with no OVS port created while service attach"
  exit 1
fi

if docker exec -it postgres ip addr show eth0 | grep 192.168.1.3/24 > /dev/null 2>&1; then : ; else
  echo "test failed with no interface seen inside container"
  exit 1
fi
