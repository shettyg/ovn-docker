# OVN demo

## Setup
Clone the repo, enter the vagrant_overlay directory and run:

    vagrant up

## test1

Log in to `node1` (`vagrant ssh node1`) and run:

    sudo sh /usr/local/bin/test1.sh

## test2

Log in to `node1` (`vagrant ssh node1`) and run:

    sudo sh /usr/local/bin/test2.sh

## test3

Log in to `node1` (`vagrant ssh node1`) and run:

    sudo sh /usr/local/bin/test3_node1.sh

Log in to `node2` (`vagrant ssh node2`) and run:

    sudo sh /usr/local/bin/test3_node2.sh


Ping the ports 
From node1:

    sudo docker exec -it busybox ping busybox1.foo

From node2:

    sudo docker exec -it postgres ping busybox.foo

To cleanup test3 creations.

From node1:

    sudo sh /usr/local/bin/test3_cleanup_node1.sh

From node2:

    sudo sh /usr/local/bin/test3_cleanup_node2.sh
