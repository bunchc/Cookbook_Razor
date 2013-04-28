#!/bin/bash

# iscsi.sh

# Authors: Cody Bunch (bunchc@gmail.com)

# Source in common env vars
. /vagrant/common.sh

# Install chef server
wget --quiet -O chef-server-11.deb https://opscode-omnitruck-release.s3.amazonaws.com/ubuntu/12.04/x86_64/chef-server_11.0.6-1.ubuntu.12.04_amd64.deb
sudo dpkg -i chef-server-11.deb

sudo chef-server-ctl reconfigure
sudo chef-server-ctl test

mkdir ~/.chef
cp /etc/chef-server/admin.pem ~/.chef
cp /etc/chef-server/chef-validator.pem ~/.chef

# Install chef client
curl -L https://www.opscode.com/chef/install.sh | sudo bash
sudo mkdir -p /var/chef/cookbooks

# Make knife.rb
sudo cat > ~/.chef <<EOF
log_level                :info
log_location             STDOUT
node_name                'chef'
client_key               '~/.chef/admin.pem'
validation_client_name   'chef-validator'
validation_key           '~/.chef/chef-validator.pem'
chef_server_url          'https://chef.book'
syntax_check_cache_path  '~/.chef/syntax_check_cache'
EOF

# Pull down the Razor & Rackspace OpenStack cookbooks
sudo git clone git://github.com/opscode/chef-repo.git /var/chef/cookbooks
sudo knife cookbook site install razor

git clone --recursive git@github.com:rcbops/chef-cookbooks.git /var/chef/cookbooks

cd /var/chef/cookbooks
knife cookbook upload -o cookbooks --all
knife role from file roles/*.rb

