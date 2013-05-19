# Install apt-cacher
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update && sudo apt-get install squid -y

rm /etc/squid3/squid.conf

sudo tee /etc/squid3/squid.conf >/dev/null <<EOF
acl manager proto cache_object
acl localhost src 127.0.0.1/32 ::1
acl to_localhost dst 127.0.0.0/8 0.0.0.0/32 ::1

# Example rule allowing access from your local networks.
# Adapt to list your (internal) IP networks from where browsing
# should be allowed
#acl localnet src 10.0.0.0/8    # RFC1918 possible internal network

acl localnet src 172.16.0.0/12 # RFC1918 possible internal network

#acl localnet src 192.168.0.0/16        # RFC1918 possible internal network
#acl localnet src fc00::/7       # RFC 4193 local private network range
#acl localnet src fe80::/10      # RFC 4291 link-local (directly plugged) machines

acl SSL_ports port 443
acl Safe_ports port 80          # http
acl Safe_ports port 21          # ftp
acl Safe_ports port 443         # https
acl Safe_ports port 70          # gopher
acl Safe_ports port 210         # wais
acl Safe_ports port 1025-65535  # unregistered ports
acl Safe_ports port 280         # http-mgmt
acl Safe_ports port 488         # gss-http
acl Safe_ports port 591         # filemaker
acl Safe_ports port 777         # multiling http
acl CONNECT method CONNECT

http_access allow manager localhost
http_access deny manager

# Deny requests to certain unsafe ports
http_access deny !Safe_ports

# Deny CONNECT to other than secure SSL ports
http_access deny CONNECT !SSL_ports

# We strongly recommend the following be uncommented to protect innocent
# web applications running on the proxy server who think the only
# one who can access services on "localhost" is a local user
#http_access deny to_localhost

#
# INSERT YOUR OWN RULE(S) HERE TO ALLOW ACCESS FROM YOUR CLIENTS
#

# Example rule allowing access from your local networks.
# Adapt localnet in the ACL section to list your (internal) IP networks
# from where browsing should be allowed

http_access allow localnet
http_access allow localhost

# And finally deny all other access to this proxy
http_access deny all

#  TAG: adapted_http_access

http_port 3128

# Add any of your own refresh_pattern entries above these.
refresh_pattern ^ftp:           1440    20%     10080
refresh_pattern ^gopher:        1440    0%      1440
refresh_pattern -i (/cgi-bin/|\?) 0     0%      0
refresh_pattern (Release|Packages(.gz)*)$      0       20%     2880
# example lin deb packages
#refresh_pattern (\.deb|\.udeb)$   129600 100% 129600
refresh_pattern .               0       20%     4320
EOF

service squid3 restart

# Setup our repo's
sudo apt-get install python-software-properties -y
sudo add-apt-repository ppa:ubuntu-cloud-archive/grizzly-staging
sudo apt-get update
sudo apt-get install iftop iptraf vim curl wget lighttpd -y

echo 'Acquire::http { Proxy "http://172.16.0.110:3142"; };' | sudo tee /etc/apt/apt.conf.d/01apt-cacher-ng-proxy

echo 'Downloading Razor images...'
wget --quiet http://mirror.anl.gov/pub/ubuntu-iso/CDs/precise/ubuntu-12.04.2-server-amd64.iso -O /var/www/ubuntu-12.04.2-server-amd64.iso
wget --quiet https://downloads.puppetlabs.com/razor/iso/dev/rz_mk_dev-image.0.12.0.iso -O /var/www/rz_mk_dev-image.0.12.0.iso

# Enable NAT for the nodes
echo 1 > /proc/sys/net/ipv4/ip_forward
sudo /sbin/iptables -t nat -A PREROUTING -i eth1 -p tcp -m tcp --dport 80 -j DNAT --to-destination 172.16.0.110:3128
sudi /sbin/iptables -t nat -A PREROUTING -i eth0 -p tcp -m tcp --dport 80 -j REDIRECT --to-ports 3128
sudo /sbin/iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo /sbin/iptables -A FORWARD -i eth0 -o eth1 -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo /sbin/iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT

