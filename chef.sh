#!/bin/bash

# iscsi.sh

# Authors: Cody Bunch (bunchc@gmail.com)

# Source in common env vars
. /vagrant/common.sh

# Install chef server
echo "Installing Chef Server..."
sudo dpkg -i /vagrant/chef-server-11.deb

sudo chef-server-ctl reconfigure
sudo chef-server-ctl test

mkdir ~/.chef
cp /etc/chef-server/admin.pem ~/.chef
cp /etc/chef-server/chef-validator.pem ~/.chef
cp /etc/chef-server/chef-validator.pem /vagrant/
cp /etc/chef-server/admin.pem /vagrant/

# Install chef client
curl -L https://www.opscode.com/chef/install.sh | sudo bash

# Make knife.rb
sudo cat > ~/.chef/knife.rb <<EOF
log_level                :info
log_location             STDOUT
node_name                'admin'
client_key               '~/.chef/admin.pem'
validation_client_name   'chef-validator'
validation_key           '~/.chef/chef-validator.pem'
chef_server_url          'https://chef.book'
cookbook_path		 '/root/cookbooks/'
syntax_check_cache_path  '~/.chef/syntax_check_cache'
EOF

# Pull down the Razor & Rackspace OpenStack cookbooks
sudo git clone git://github.com/opscode/chef-repo.git /root/cookbooks
sudo git clone --recursive git://github.com/rcbops/chef-cookbooks.git /root/alamo
sudo git clone https://github.com/spheromak/dhcp-cook.git /root/dhcp
sudo knife cookbook site install razor

# Configure the Razor cookbooks
RAZOR_IP=\"172.16.0.101\"
sudo sed -i "s/node\['ipaddress'\]/$RAZOR_IP/g" /root/cookbooks/razor/attributes/default.rb

# Configure the DHCP cookbooks
INTERFACE=\"eth1\"
sudo sed -i "s/default\[:dhcp\]\[:interfaces\] = \[\]/default\[:dhcp\]\[:interfaces\] = \[ $INTERFACE \]/g" /root/dhcp/attributes/default.rb
sudo sed -i 's/default\[:dhcp\]\[:parameters\]\[:"next-server"\] = ipaddress/default\[:dhcp\]\[:parameters\]\[:"next-server"\] = '$RAZOR_IP'/g' /root/dhcp/attributes/default.rb
sudo sed -i 's/default\[:dhcp\]\[:networks\] = \[\]/default\[:dhcp\]\[:networks\] = \[ "172-16-0-0_24" \]/g' /root/dhcp/attributes/default.rb

# More DHCP Config
sudo knife databag create dhcp_networks
mkdir -p /root/databags/dhcp_networks
sudo cat > /root/databags/dhcp_networks/razor_dhcp.json <<EOF
{
	"id": "172-16-0-0_24",
	"routers": [ "172.16.0.2" ],
	"address": "172.16.0.0",
	"netmask": "255.255.255.0",
	"broadcast": "172.16.0.255",
	"range": "172.16.0.50 172.16.0.59",
	"options": [ "next-server 172.16.0.101" ]
}
EOF
sudo knife data bag from file dhcp_networks /root/databags/dhcp_networks/razor_dhcp.json

# Upload all the things!
sudo knife cookbook upload -o /root/alamo/cookbooks --all
sudo knife cookbook upload -o /root/cookbooks --all
sudo knife cookbook upload -o  /root/dhcp --all
sudo knife role from file /root/alamo/roles/*.rb

