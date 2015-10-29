# OVN demo

## Setup
Clone the repo, enter the vagrant directory and run:

    vagrant up

## Test

Log in to `node1` (`vagrant ssh node1`) and run:

    sudo sh /vagrant/setup-nw-node1.sh

Log in to `node2` (`vagrant ssh node2`) and run:

    sudo sh /vagrant/setup-nw-node2.sh

Get assigned IP addresses from ports:

    sudo ovn-container endpoint-list

Ping the ports (this should work from both nodes)

    sudo docker exec -it networktest ping -c 3 192.168.1.2
    sudo docker exec -it networktest ping -c 3 192.168.1.3

