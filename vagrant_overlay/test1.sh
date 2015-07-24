# Create a network, list it, delete it, list it.

IPAM_IP=`sudo ovs-vsctl get Open-vSwitch . external_ids:ipam | sed 's/"//g'`
NID=`docker network create -d openvswitch foo`
neutron net-create $NID --tenant-id admin --os-url http://$IPAM_IP:9696/ --os-auth-strategy="noauth"
neutron subnet-create $NID 192.168.1.0/24 --tenant-id admin --os-url http://$IPAM_IP:9696/ --os-auth-strategy="noauth"

if docker network ls | grep foo 2>&1 >/dev/null; then :; else
  echo "test failed while creating network"
fi

docker network rm foo

if docker network ls | grep foo 2>&1 >/dev/null; then
  echo "test failed while deleting network"
fi

if neutron net-show $NID --tenant-id admin --os-url http://$IPAM_IP:9696/ --os-auth-strategy="noauth" 2>/dev/null; then
  echo "test failed with neutron networt not deleted"
fi
