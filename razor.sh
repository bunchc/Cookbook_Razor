#!/bin/bash

# iscsi.sh

# Authors: Cody Bunch (bunchc@gmail.com)

# Source in common env vars
. /vagrant/common.sh

mkdir -p /etc/chef
cp /vagrant/chef-validator.pem /etc/chef/validation.pem

sudo echo "172.16.172.100	chef.book" >> /etc/hosts

# Install chef client
curl -L https://www.opscode.com/chef/install.sh | sudo bash

# Make knife.rb
sudo cat > /etc/chef/client.rb <<EOF
log_level	:info
log_location	STDOUT
chef_server_url	'https://chef.book/'
validation_client_name	'chef-validator'
EOF

sudo chef-client
