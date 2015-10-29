wget -qO- https://get.docker.com/ | sh
apt-get install -q -y vim bridge-utils 

echo 'DOCKER_OPTS="--bridge=docker0"' >> /etc/default/docker
service docker restart
