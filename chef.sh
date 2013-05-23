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
chef_server_url          'https://chef.cook.book'
cookbook_path		 '/root/cookbooks/'
syntax_check_cache_path  '~/.chef/syntax_check_cache'
EOF

# Pull down the Razor & Rackspace OpenStack cookbooks
sudo git clone git://github.com/opscode/chef-repo.git /root/cookbooks
sudo git clone -b grizzly --recursive git://github.com/rcbops/chef-cookbooks.git /root/alamo
sudo knife cookbook site install razor
sudo knife cookbook site install dhcp

# This is here until the upstream cookbook gets updated:
sudo cat > /root/cookbooks/dhcp/templates/default/dhcpd.conf.erb <<EOF
# File managed by Chef

# set this to store vendor strings.
set vendor-string = option vendor-class-identifier;

<% @allows.each do |allow| -%>
allow <%= allow %>;
<% end -%>

<% @parameters.sort.each do |key, value| -%>
  <%= key %> <%= value %>;
  <% end -%>

  <% @options.sort.each do |key, value| -%>
    option <%= key %> <%= value %>;
    <% end -%>

    <% unless @keys.nil? || @keys.empty? -%>
      <% @keys.each do |key, data| -%>
      key "<%= key %>" {
        algorithm <%= data['algorithm'] %>;
	  secret "<%= data['secret'] %>";
	  };
	    <%end -%>
	    <%end -%>

	    <% unless @masters.nil? || @masters.empty? -%>
	    <% @masters.each do |zone, data| -%>
	    zone <%= zone %>. {
	      primary <%= data["master"] %>;
	        key "<%= data["key"] %>";
		}
		  <% end -%>
		  <% end -%>

		  <% if @failover %>
		  failover peer "<%= node[:domain] %>" { 
		    <%= @role %>; 
		      address <%= @my_ip %>;     
		        port 647;
			  peer address <%= @peer_ip %>;
			    peer port 647;
			      max-response-delay 60;
			        max-unacked-updates 10;
				  mclt 3600;
				    <% if @role =~ /primary/i -%>
				      split 128;
				        load balance max seconds 3;
					  <% end -%>
					  }
					  <% end %>

					  include "<%= node[:dhcp][:dir] %>/groups.d/list.conf";
					  include "<%= node[:dhcp][:dir] %>/subnets.d/list.conf";
					  include "<%= node[:dhcp][:dir] %>/hosts.d/list.conf";

EOF

# More DHCP Config
sudo knife data bag create dhcp_networks
mkdir -p /root/databags/dhcp_networks
sudo cat > /root/databags/dhcp_networks/razor_dhcp.json <<EOF
{
	"id": "172-16-0-0_24",
	"routers": [ "172.16.0.110" ],
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
sudo knife role from file /root/alamo/roles/*.rb
sudo knife environment from file /vagrant/openstack.json
