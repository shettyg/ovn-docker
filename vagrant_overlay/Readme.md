# OVN demo

## Setup
Clone the repo, enter the vagrant_overlay directory and run:

    vagrant up

## test1

Log in to `node1` (`vagrant ssh node1`) and run:

    sudo sh /vagrant/test1.sh

## test2

Log in to `node1` (`vagrant ssh node1`) and run:

    sudo sh /vagrant/test2.sh

## test3

Log in to `node1` (`vagrant ssh node1`) and run:

    sudo sh /vagrant/test3.sh

Log in to `node2` (`vagrant ssh node2`) and run:

    sudo sh /vagrant/test3.sh


Get assigned IP addresses from ports:

    sudo ovn-container endpoint-list

Ping the ports (this should work from both nodes)

    sudo docker exec -it networktest ping -c 3 192.168.1.2
    sudo docker exec -it networktest ping -c 3 192.168.1.3

