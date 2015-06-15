# OVN demo

## Setup

    vagrant up

## Test

Log in to `node1` and run:

    sh /vagrant/setup-nw-node1.sh

Log in to `node2` and run:

    sh /vagrant/setup-nw-node2.sh

Get assigend IP addresses from ports:

    ovn-container endpoint-list

Ping the ports (this should work from both nodes)

    docker exec -it networktest ping -c 3 ping 192.168.1.2
    docker exec -it networktest ping -c 3 ping 192.168.1.3

