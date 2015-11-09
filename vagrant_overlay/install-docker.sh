IP=$1
service docker stop
wget -qO- https://get.docker.com/ | sh
DOCKER_OPTS="--cluster-store=consul://127.0.0.1:8500 --cluster-advertise=$IP:0"
echo DOCKER_OPTS=\"$DOCKER_OPTS\" >> /etc/default/docker

service docker restart
