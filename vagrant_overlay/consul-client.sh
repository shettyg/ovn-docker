IP=$1
SERVER_IP=$2
apt-get update
apt-get install unzip -y
wget https://releases.hashicorp.com/consul/0.6.3/consul_0.6.3_linux_amd64.zip
unzip consul_0.6.3_linux_amd64.zip
cp consul /usr/sbin/.
nohup consul agent -data-dir /tmp/consul -bind=$IP > /dev/null 2>&1 &
sleep 5
consul join $SERVER_IP
