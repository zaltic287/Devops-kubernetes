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
sudo sh install_salt.sh -P 2>&1 >/dev/null

echo "
master: salt1
" >/etc/salt/minion

sudo systemctl restart salt-minion
