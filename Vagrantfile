# -*- mode: ruby -*-
# vi: set ft=ruby :

nodes = {
    'proxy'	=> [1, 110],
    'chef'  => [1, 100],
    'razor'   => [1, 101],
    'node'   => [3, 103],
}

Vagrant.configure("2") do |config|
    config.vm.box = "precise64"
    config.vm.box_url = "http://files.vagrantup.com/precise64.box"

    #Default is 2200..something, but port 2200 is used by forescout NAC agent.
    config.vm.usable_port_range= 2800..2900 

    nodes.each do |prefix, (count, ip_start)|
        count.times do |i|
            if prefix == "node"
	        hostname = "%s-%02d" % [prefix, (i+1)]
	    else
                hostname = "%s" % [prefix, (i+1)]
	    end

            config.vm.define "#{hostname}" do |box|
                box.vm.hostname = "#{hostname}.cook.book"
                box.vm.network :private_network, ip: "172.16.0.#{ip_start+i}", :netmask => "255.255.0.0"
		if prefix == "node"
		    box.vm.box = "razor_node"
		    box.vm.box_url = "http://openstack.prov12n.com/files/razor_node.box"
		end

                box.vm.provision :shell, :path => "#{prefix}.sh"

                # If using Fusion
                box.vm.provider :vmware_fusion do |v|
                    v.vmx["memsize"] = 1024
        	    if prefix == "chef"
	              	v.vmx["memsize"] = 2048
	            elsif prefix == "proxy"
    	                v.vmx["memsize"] = 512
	            end
                end

                # Otherwise using VirtualBox
                box.vm.provider :virtualbox do |vbox|
	            # Defaults
                    vbox.customize ["modifyvm", :id, "--memory", 1024]
                    vbox.customize ["modifyvm", :id, "--cpus", 1]
		    if prefix == "chef"
                    	vbox.customize ["modifyvm", :id, "--memory", 3128]
                        vbox.customize ["modifyvm", :id, "--cpus", 2]
		    elsif prefix == "proxy"
		        vbox.customize ["modifyvm", :id, "--memory", 512]
		    elsif prefix == "node"
			vbox.gui = true
			vbox.customize ["modifyvm", :id, "--boot1", "net"]
			vbox.customize ["modifyvm", :id, "--nic1", "hostonly"]
			vbox.customize ["modifyvm", :id, "--hostonlyadapter1", "vboxnet0"]
			vbox.customize ["modifyvm", :id, "--memory", 3128]
		    end
                end
            end
        end
    end
end
