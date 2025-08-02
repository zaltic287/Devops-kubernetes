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



# Let's Go !! #################################################


curl -sL https://bootstrap.saltstack.com -o install_salt.sh 2>&1 >/dev/null 
chmod 755 install_salt.sh
sudo sh install_salt.sh -P -M 2>&1 >/dev/null
sudo mkdir -p /srv/{salt,pillar}/base
sudo chown -R vagrant:vagrant  /srv/
sudo chmod 775 -R   /srv/

echo "
auto_accept: True
file_roots:
  base:
    - /srv/salt/base/
pillar_roots:
  base:
    - /srv/pillar/base
" >> /etc/salt/master

echo "
master: 127.0.0.1
" >/etc/salt/minion

sudo systemctl restart salt-master
sudo systemctl restart salt-minion

