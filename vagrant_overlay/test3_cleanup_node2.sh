# clean up test3 node2
# Stop and delete container
docker stop postgres
docker rm postgres

# Delete service
docker service unpublish mydb.foo

# Delete network
docker network rm foo
