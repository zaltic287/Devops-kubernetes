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


clean_host(){
sed -i /'^127.0.1.1.*'/d /etc/hosts
}

install_elasticsearch(){
apt install gnupg2 -y -qq 2>&1 >/dev/null
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" > /etc/apt/sources.list.d/elastic-7.x.list
apt update -qq 2>&1 >/dev/null
apt install -y -qq elasticsearch=7.14.0 2>&1 >/dev/null
}

install_elasticsearch_config(){
sed -i s/"#discovery.seed_hosts:".*/"discovery.seed_hosts: [\"janus1\"]"/g /etc/elasticsearch/elasticsearch.yml
sed -i s/"#network.host:".*/"network.host: ${IP}"/g /etc/elasticsearch/elasticsearch.yml
sed -i s/"http.host:".*/"http.host: ${IP}"/g /etc/elasticsearch/elasticsearch.yml
sed -i s/"#cluster.name:".*/"cluster.name: Saliou"/g /etc/elasticsearch/elasticsearch.yml
sed -i s/"#node.name:".*/"node.name: $(hostname)"/g /etc/elasticsearch/elasticsearch.yml
sed -i s/"xpack.security.enabled:".*/"xpack.security.enabled: false"/g /etc/elasticsearch/elasticsearch.yml
sed -i s/"enabled: ".*/"enabled: false"/g /etc/elasticsearch/elasticsearch.yml
sed -i s/"#cluster.initial_master_nodes: ".*/"cluster.initial_master_nodes: [\"janus1\"]"/g /etc/elasticsearch/elasticsearch.yml

echo "-Xms2g" >> /etc/elasticsearch/jvm.options
echo "-Xmx2g" >> /etc/elasticsearch/jvm.options
}

start_elasticsearch(){
sudo systemctl enable elasticsearch
sudo systemctl restart elasticsearch
}

# Let's Go !! #################################################

clean_host
install_elasticsearch
install_elasticsearch_config
start_elasticsearch
