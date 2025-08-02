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



# Functions ###################################################

install_benthos(){
  curl -Lsf https://sh.benthos.dev | bash 2>&1 >/dev/null
}

install_scylla_tool(){
apt install -y python3-pip
pip3 install cqlsh
cqlsh scylla1 -e "CREATE KEYSPACE IF NOT EXISTS Saliou WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 2} ;"
cqlsh scylla1 -e "CREATE TABLE IF NOT EXISTS Saliou.T1 ( uid varchar PRIMARY KEY, text varchar );"
}

benthos_sample_config(){
echo "
input:
  generate:
    count: 1000000
    interval: ''
    mapping: |
      root.id = uuid_v4()
      root.message = \"Je suis un message \" + random_int().string()

output:
  cassandra:
    addresses:
      - scylla1:9042
      - scylla2:9042
      - scylla3:9042
    query: 'INSERT INTO Saliou.T1 (uid, text) VALUES (?, ?)'
    args_mapping: |
      root = [
        this.id,
        this.message,
      ]
" >/home/vagrant/scylla_sample.yml
}

# Let's Go !! #################################################

install_benthos
#install_scylla_tool
benthos_sample_config
