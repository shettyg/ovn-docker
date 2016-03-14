IP=$1
apt-get update
apt-get install unzip
wget https://releases.hashicorp.com/consul/0.6.3/consul_0.6.3_linux_amd64.zip
unzip consul_0.6.3_linux_amd64.zip
cp consul /usr/sbin/.
nohup consul agent -server -bootstrap -data-dir /tmp/consul -bind=$1 > /dev/null 2>&1 &
