# clean up test3 node2
# Stop and delete container
docker stop -t busybox1
docker rm busybox1

# Delete network
docker network rm foo
