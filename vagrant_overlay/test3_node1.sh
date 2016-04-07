# Multi-host node1

OVN_REMOTE=`ovs-vsctl get o . external_ids:ovn-nb | sed 's/"//g'`

# Create network foo

NID=`docker network create -d openvswitch --subnet 192.168.1.0/24 foo`

if docker network ls | grep foo 2>&1 >/dev/null; then :; else
  echo "test failed with no network seen"
  exit 1
fi


# Create and attach service at same time

docker run -itd --net=foo --name=busybox busybox

if docker exec -it busybox ip addr show eth0 | grep 192.168.1.2/24 > /dev/null 2>&1; then : ; else
  echo "test failed with no interface seen inside container"
  exit 1
fi
