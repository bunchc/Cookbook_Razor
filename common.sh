#!/bin/bash

# common.sh
#
# Authors: Kevin Jackson (kevin@linuxservices.co.uk)
#          Cody Bunch (bunchc@gmail.com)
#
# Sets up common bits used in each build script.
#

export DEBIAN_FRONTEND=noninteractive

# Setup Proxy
export APT_PROXY="172.16.0.110"
#APT_PROXY="192.168.1.1:3128"
#
# If you have a proxy outside of your VirtualBox environment, use it
if [[ ! -z "$APT_PROXY" ]]
then
	echo 'Acquire::http { Proxy "http://'${APT_PROXY}:3128'"; };' | sudo tee /etc/apt/apt.conf.d/01apt-cacher-ng-proxy
fi

sudo apt-get update
# Grizzly Goodness
sudo apt-get -y install ubuntu-cloud-keyring
echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu precise-updates/grizzly main" | sudo tee -a /etc/apt/sources.list.d/grizzly.list

sudo apt-get install -y git curl wget vim

