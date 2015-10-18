# Create a network, connect it, disconnect it etc
OVN_REMOTE=`ovs-vsctl get o . external_ids:ovn-remote | sed 's/"//g'`

# Create network foo

NID=`docker network create -d openvswitch --subnet 192.168.1.0/24 foo`

if docker network ls | grep foo 2>&1 >/dev/null; then :; else
  echo "test failed with no network seen"
  exit 1
fi


# Start a container
docker run -itd  --name busybox busybox


# Create an endpoint and join
docker network connect foo busybox

if docker exec -it busybox ip addr show eth1 | grep 192.168.1.2/24 > /dev/null 2>&1; then : ; else
  echo "test failed with no interface seen inside container"
  exit 1
fi

# disconnect
docker network disconnect foo busybox

docker stop -t 1 busybox
docker rm busybox

# Create and attach port at same time
docker run -itd --net=foo --name busybox busybox


if docker exec -it busybox ip addr show eth0 | grep 192.168.1.2/24 > /dev/null 2>&1; then : ; else
  echo "test failed with no interface seen inside container"
  exit 1
fi

# Stop and delete container
docker stop -t 1 busybox
docker rm busybox

# Delete network

docker network rm foo

if docker network ls | grep foo 2>&1 >/dev/null; then
  echo "test failed with no network seen"
  exit 1
fi

logical_switch=`ovn-nbctl --db=$OVN_REMOTE --if-exists get logical_switch $NID name`

if [ -n "$logical_switch" ]; then
   echo "Logical switch in OVN still exists after deleting docker network"
   exit 1
fi
