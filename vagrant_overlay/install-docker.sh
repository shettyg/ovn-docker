IP=$1

# Add external server for OVS packages here to prevent multiple 'apt-get update'
sudo apt-get install apt-transport-https
echo "deb https://packages.wand.net.nz $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/wand.list
sudo curl https://packages.wand.net.nz/keyring.gpg -o /etc/apt/trusted.gpg.d/wand.gpg

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
