# clean up test3
# Stop and delete container
docker stop postgres
docker rm postgres

# Delete service
docker service unpublish app.foo
