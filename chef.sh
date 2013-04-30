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
syntax_check_cache_path  '~/.chef/syntax_check_cache'
EOF

# Pull down the Razor & Rackspace OpenStack cookbooks
sudo git clone git://github.com/opscode/chef-repo.git /var/chef
git clone --recursive git://github.com/rcbops/chef-cookbooks.git /tmp/chef

shopt -s dotglob
cp -R /tmp/chef/* /var/chef/
cd /var/chef/

sudo knife cookbook site install razor

sudo knife cookbook upload -o /var/chef/cookbooks --all
sudo knife role from file /var/chef/roles/*.rb

