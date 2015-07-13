IP=$1
SERVER_IP=$2
apt-get install unzip
wget https://dl.bintray.com/mitchellh/consul/0.5.2_linux_amd64.zip
unzip 0.5.2_linux_amd64.zip
cp consul /usr/sbin/.
nohup consul agent -data-dir /tmp/consul -bind=$IP > /dev/null 2>&1 &
sleep 5
consul join $SERVER_IP
