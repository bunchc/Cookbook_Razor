#!/bin/bash

# iscsi.sh

# Authors: Cody Bunch (bunchc@gmail.com)

# Source in common env vars
. /vagrant/common.sh

mkdir -p /etc/chef
cp /vagrant/chef-validator.pem /etc/chef/validation.pem

# Install chef client
curl -L https://www.opscode.com/chef/install.sh | sudo bash

# Setup some entries
sudo cat > /etc/hosts <<EOF
127.0.0.1	localhost
172.16.0.101	razor.cook.book razor precise64

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
172.16.0.100         chef.cook.book
EOF

# Make client.rb
sudo cat > /etc/chef/client.rb <<EOF
log_level       :info
log_location    STDOUT
chef_server_url 'https://chef.cook.book/'
validation_client_name  'chef-validator'
EOF

# Make knife.rb
mkdir ~/.chef
sudo cat > ~/.chef/knife.rb <<EOF
log_level                :info
log_location             STDOUT
node_name                'admin'
client_key               '~/.chef/admin.pem'
validation_client_name   'chef-validator'
validation_key           '~/.chef/chef-validator.pem'
chef_server_url          'https://chef.cook.book'
cookbook_path            '/root/cookbooks/'
syntax_check_cache_path  '~/.chef/syntax_check_cache'
EOF

# Grab our certificates
cp /vagrant/*.pem ~/.chef

# Create our razor node & install razor & dhcp:
sudo cat > ~/.chef/razor.json <<EOF
{
    "name": "razor.cook.book",
    "chef_environment": "_default",
    "normal": {
	"dhcp": {
            "parameters": {
                "next-server": "172.16.0.101"
            },
	    "options": {
		"domain-name-servers": "172.16.0.101"
	    },
            "networks": [ "172-16-0-0_24" ],
	    "networks_bag": "dhcp_networks"
        },
        "razor": {
            "bind_address": "172.16.0.101",
            "images": {
                "razor-mk": {
                    "type": "mk",
                    "url": "https://github.com/johnmdilley/Razor-Microkernel/releases/download/0.12-tlc5-alpha3/rz_mk_debug-image.0.12.0.5-gff2f212-dirty.iso",
                    "action": "add"
                },
                "precise64": {
                    "url": "http://mirror.anl.gov/pub/ubuntu-iso/CDs/precise/ubuntu-12.04.2-server-amd64.iso",
                    "version": "12.04",
                    "action": "add"
                },
                "centos64": {
                        "url": "http://mirror.rackspace.com/CentOS/6/isos/x86_64/CentOS-6.4-x86_64-minimal.iso",
                        "version": "6.4",
                        "action": "add"
                }
            }
        },
        "tags": []
    },
    "run_list": [
            "recipe[razor]",
            "recipe[dhcp::server]"
    ]
}
EOF

knife node from file ~/.chef/razor.json

sudo chef-client

# Setup some entries and install DNSMasq
sudo apt-get install -y dnsmasq
