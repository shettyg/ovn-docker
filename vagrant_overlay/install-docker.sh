IP=$1

# Add external server for OVS packages here to prevent multiple 'apt-get update'
sudo apt-get install apt-transport-https
echo "deb http://18.191.116.101/openvswitch/stable /" |  sudo tee /etc/apt/sources.list.d/openvswitch.list
wget -O - http://18.191.116.101/openvswitch/keyFile |  sudo apt-key add -

# Install docker
service docker stop
wget -qO- https://get.docker.com/ | sh

cat <<EOF >> /etc/docker/daemon.json
{
    "cluster-advertise": "$1:0",
    "cluster-store": "consul://127.0.0.1:8500"
}
EOF


service docker restart
