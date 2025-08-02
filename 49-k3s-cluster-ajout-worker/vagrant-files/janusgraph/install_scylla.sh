#!/usr/bin/bash

###############################################################
#  TITRE: 
#
#  AUTEUR:   Xavier
#  VERSION: 
#  CREATION:  
#  MODIFIE: 
#
#  DESCRIPTION: 
###############################################################



# Variables ###################################################

IP=$(hostname -I | awk '{print $2}')

# Functions ###################################################

install_prerequisites(){

# Swap off
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# Disable THP
sudo /bin/bash -c 'echo never > /sys/kernel/mm/transparent_hugepage/enabled'
sudo sed -i s/"quiet splash"/"transparent_hugepage=never quiet splash"/g /etc/default/grub
sudo update-grub

# Set swappiness to 0
sudo /bin/bash -c 'echo vm.swappiness = 0 > /etc/sysctl.d/99-sysctl.conf'
sudo sysctl -p


}

clean_host(){
sed -i /'^127.0.1.1.*'/d /etc/hosts
}

install_scylla(){
mkdir -p /etc/apt/keyrings
gpg --homedir /tmp --no-default-keyring --keyring /etc/apt/keyrings/scylladb.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys d0a112e067426ab2
wget -O /etc/apt/sources.list.d/scylla.list http://downloads.scylladb.com/deb/debian/scylla-5.1.list
apt update -qq 2>&1 >/dev/null
apt-get install -y -qq scylla 2>&1 >/dev/null
#scylla_setup --no-raid-setup --online-discard=1 --nic eth1 --no-verify-package --no-enable-service --no-ntp-setup --io-setup 1 --no-version-check --no-rsyslog-setup 2>&1 >/dev/null
}

install_cluster(){
sed -i s/"listen_address:.*"/"listen_address: "${IP}/g /etc/scylla/scylla.yaml
sed -i s/"rpc_address:.*"/"rpc_address: "${IP}/g /etc/scylla/scylla.yaml
sed -i s/"seeds: .*"/"seeds: \"janus1\""/g /etc/scylla/scylla.yaml
echo "cluster_name: 'Saliou'" >> /etc/scylla/scylla.yaml
echo "developer_mode: true" >> /etc/scylla/scylla.yaml
echo "broadcast_rpc_address: ${IP}" >> /etc/scylla/scylla.yaml
echo "prometheus_address: ${IP}" >> /etc/scylla/scylla.yaml
systemctl restart scylla-server
systemctl enable scylla-server
}

# Let's Go !! #################################################

install_prerequisites
clean_host
install_scylla
install_cluster
