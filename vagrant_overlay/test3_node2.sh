# Multi-host node2

docker run -itd --net=foo --name=busybox1 busybox

if docker exec -it busybox1 ip addr show eth0 | grep 192.168.1.3/24 > /dev/null 2>&1; then : ; else
  echo "test failed with no interface seen inside container"
  exit 1
fi
