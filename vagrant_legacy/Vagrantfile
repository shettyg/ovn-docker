# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

    config.vm.define "node1" do |node|
      node.vm.box = "ubuntu/trusty64"
      node.vm.network "private_network", ip: "192.168.50.101"
      node.vm.host_name = "node1"
      node.vm.provision "shell", path: "install-docker.sh"
      node.vm.provision "shell", path: "install-ovn.sh"
      node.vm.provision "shell", path: "run-ipam.sh"
      node.vm.provision "shell", path: "run-ovn.sh", :args => "192.168.50.101 192.168.50.101"
    end

    config.vm.define "node2" do |node|
      node.vm.box = "ubuntu/trusty64"
      node.vm.network "private_network", ip: "192.168.50.102"
      node.vm.host_name = "node2"
      node.vm.provision "shell", path: "install-docker.sh"
      node.vm.provision "shell", path: "install-ovn.sh"
      node.vm.provision "shell", path: "run-ovn.sh", :args => "192.168.50.101 192.168.50.102"
    end

end
