containers=`docker ps -a | grep -v CONTAINER | awk '{print $1}'`
for container in $containers; do
docker stop $container
docker rm $container
done
