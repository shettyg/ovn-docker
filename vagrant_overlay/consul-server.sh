IP=$1
apt-get update
apt-get install unzip
wget https://dl.bintray.com/mitchellh/consul/0.5.2_linux_amd64.zip
unzip 0.5.2_linux_amd64.zip
cp consul /usr/sbin/.
nohup consul agent -server -bootstrap -data-dir /tmp/consul -bind=$1 > /dev/null 2>&1 &
