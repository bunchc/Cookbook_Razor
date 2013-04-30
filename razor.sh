#!/bin/bash

# iscsi.sh

# Authors: Cody Bunch (bunchc@gmail.com)

# Source in common env vars
. /vagrant/common.sh

mkdir -p /etc/chef
cp /vagrant/chef-validator.pem /etc/chef/validation.pem

sudo echo "172.16.0.100		chef.book" >> /etc/hosts

# Install chef client
curl -L https://www.opscode.com/chef/install.sh | sudo bash

# Make client.rb
sudo cat > /etc/chef/client.rb <<EOF
log_level	:info
log_location	STDOUT
chef_server_url	'https://chef.book/'
validation_client_name	'chef-validator'
EOF

# Make knife.rb
sudo cat > ~/.chef/knife.rb <<EOF
log_level                :info
log_location             STDOUT
node_name                'admin'
client_key               '~/.chef/admin.pem'
validation_client_name   'chef-validator'
validation_key           '~/.chef/chef-validator.pem'
chef_server_url          'https://chef.book'
cookbook_path            '/root/cookbooks/'
syntax_check_cache_path  '~/.chef/syntax_check_cache'
EOF

# Grab our certificates
mkdir ~/.chef
cp /vagrant/*.pem ~/.chef

# Register with the Chef-Server
sudo chef-client

# Install us some Razor
knife node run_list add razor.book razor
sudo chef-client

