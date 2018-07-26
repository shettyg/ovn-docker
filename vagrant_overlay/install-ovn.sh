apt-get build-dep dkms
apt-get install python-six openssl python-pip -y
pip install --upgrade pip==9.0.3
pip install flask

apt-get install openvswitch-datapath-dkms=2.9.2-1 -y
apt-get install openvswitch-switch=2.9.2-1 openvswitch-common=2.9.2-1 \
    python-openvswitch=2.9.2-1 -y

ovs-vsctl set Open_vSwitch . external_ids:ovn-remote="tcp:$1:6642"
ovs-vsctl set Open_vSwitch . external_ids:ovn-nb="tcp:$1:6641"
ovs-vsctl set Open_vSwitch . external_ids:ovn-encap-ip="$2"
ovs-vsctl set Open_vSwitch . external_ids:ovn-encap-type="geneve"

apt-get install ovn-central=2.9.2-1 ovn-common=2.9.2-1 ovn-host=2.9.2-1 \
    ovn-docker=2.9.2-1 -y

/usr/share/openvswitch/scripts/ovn-ctl start_controller

ovn-nbctl set-connection ptcp:6641
ovn-sbctl set-connection ptcp:6642

git clone https://github.com/shettyg/ovn-docker.git
cd ovn-docker
cd vagrant_overlay
chmod 755 test1.sh test2.sh test3_node1.sh test3_node2.sh test3_cleanup_node1.sh test3_cleanup_node2.sh clean_all.sh
cp *.sh /usr/local/bin
sh /usr/local/bin/clean_all.sh

mkdir -p /etc/docker/plugins

ovn-docker-overlay-driver  --detach
