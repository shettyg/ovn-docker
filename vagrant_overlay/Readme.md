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

    sudo sh /vagrant/test3_node1.sh

Log in to `node2` (`vagrant ssh node2`) and run:

    sudo sh /vagrant/test3_node2.sh


Ping the ports 
From node1:

    sudo docker exec -it postgres ping mydb.foo

From node2:

    sudo docker exec -it postgres ping app.foo

To cleanup test3 creations.

From node1:

    sudo sh /vagrant/test3_cleanup_node1.sh

From node2:

    sudo sh /vagrant/test3_cleanup_node2.sh
