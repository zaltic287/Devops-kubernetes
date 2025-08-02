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

PULSAR_VERSION=3.0.0

# Functions ###################################################

installation_pulsar_user(){

swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

groupadd --system pulsar
useradd -s /sbin/nologin --system -g pulsar pulsar

}

installation_pulsar_archive(){

wget -q https://dlcdn.apache.org/pulsar/pulsar-${PULSAR_VERSION}/apache-pulsar-${PULSAR_VERSION}-bin.tar.gz 2>&1 >/dev/null
tar xzf apache-pulsar-${PULSAR_VERSION}-bin.tar.gz 2>&1 >/dev/null

mv apache-pulsar-${PULSAR_VERSION} /opt/pulsar

}

installation_pulsar_directories(){

mkdir /opt/pulsar/logs


mkdir -p /data/{pulsar,bookeeper,zookeeper}

chown -R pulsar:pulsar /opt/pulsar /data/

}




## Run #########################################################

installation_pulsar_user
installation_pulsar_archive
installation_pulsar_directories
