IP=$1
service docker stop
wget -qO- https://get.docker.com/ | sh

cat <<EOF >> /etc/docker/daemon.json
{
    "cluster-advertise": "$1:0",
    "cluster-store": "consul://127.0.0.1:8500"
}
EOF


service docker restart
