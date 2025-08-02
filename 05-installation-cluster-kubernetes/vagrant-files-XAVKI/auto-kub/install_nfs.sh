#!/bin/bash

# install nfs server


# get some variables #####################################################################

IP_RANGE=$(dig +short autohaprox | sed s/".[0-9]*$"/.0/g)


# Functions #####################################################################


prepare_directories(){

sudo mkdir -p /srv/wordpress/{db,files}
sudo mkdir -p /srv/monitoring/{alertmanager,prometheus}
sudo mkdir -p /srv/provisionner/
sudo mkdir -p /srv/{minio,rabbitmq,efk}
sudo chmod 777 -R /srv/

}

install_nfs(){

sudo apt-get install -y nfs-kernel-server 2>&1 > /dev/null

}

set_nfs(){

sudo echo "/srv/wordpress/db ${IP_RANGE}/24(rw,sync,no_root_squash,no_subtree_check)">/etc/exports
sudo echo "/srv/wordpress/files ${IP_RANGE}/24(rw,sync,no_root_squash,no_subtree_check)">>/etc/exports
sudo echo "/srv/monitoring/prometheus ${IP_RANGE}/24(rw,sync,no_root_squash,no_subtree_check)">>/etc/exports
sudo echo "/srv/monitoring/alertmanager ${IP_RANGE}/24(rw,sync,no_root_squash,no_subtree_check)">>/etc/exports
sudo echo "/srv/provisionner ${IP_RANGE}/24(rw,sync,no_root_squash,no_subtree_check)">>/etc/exports
sudo echo "/srv/minio ${IP_RANGE}/24(rw,sync,no_root_squash,no_subtree_check)">>/etc/exports
sudo echo "/srv/rabbitmq ${IP_RANGE}/24(rw,sync,no_root_squash,no_subtree_check)">>/etc/exports

}

run_nfs(){

sudo systemctl restart nfs-server rpcbind
sudo exportfs -a

}

# Let's go #######################################################################

prepare_directories
install_nfs
set_nfs
run_nfs
