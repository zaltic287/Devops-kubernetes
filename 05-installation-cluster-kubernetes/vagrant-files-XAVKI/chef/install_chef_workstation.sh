#!/usr/bin/bash

apt-get update -y -qq > /dev/null
apt-get upgrade -y -qq > /dev/null
apt-get -y -q install linux-headers-$(uname -r) build-essential > /dev/null

wget -qq -P /tmp https://packages.chef.io/files/stable/chef-workstation/22.1.745/ubuntu/20.04/chef-workstation_22.1.745-1_amd64.deb > /dev/null
dpkg -i /tmp/chef-workstation_22.1.745-1_amd64.deb
sudo -u vagrant -- chef generate repo chef-repo --chef-license=accept
mkdir -p /home/vagrant/chef-repo/.chef
chown vagrant -R /home/vagrant/chef-repo/
cd chef-repo

mkdir -p /home/vagrant/.ssh/
chown vagrant /home/vagrant/.ssh/

echo "
Host *
  StrictHostKeyChecking no
"> /home/vagrant/.ssh/config

chmod 600 /vagrant/sshkey
chown vagrant /vagrant/sshkey
sudo -u vagrant -- scp -i /vagrant/sshkey root@chef-server:/home/vagrant/certs/*.pem /home/vagrant/chef-repo/.chef/
sudo -u vagrant -- git config --global user.email "you@example.com"
sudo -u vagrant -- git config --global user.name "Saliou"

cp /vagrant/config.rb /home/vagrant/chef-repo/.chef/config.rb
sudo -u vagrant -- knife ssl fetch
sudo -u vagrant -- knife client list

cd /home/vagrant/chef-repo
knife bootstrap 192.168.14.49 -U vagrant -P vagrant --sudo --ssh-verify-host-key never --chef-license accept --node-name chef-client

#knife bootstrap 192.168.14.52 -U vagrant -P vagrant --sudo --ssh-verify-host-key never --chef-license accept --node-name chef-node
