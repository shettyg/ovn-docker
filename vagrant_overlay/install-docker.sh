IP=$1
service docker stop
DOCKER_OPTS="--cluster-store=consul://127.0.0.1:8500 --cluster-advertise=$IP:0 --bridge=docker0"
echo DOCKER_OPTS=\"$DOCKER_OPTS\" >> /etc/default/docker

cp /vagrant/docker-1.9.0-dev `which docker`
service docker start
