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

apt install -y resolvconf
systemctl start resolvconf.service
systemctl enable resolvconf.service

echo 'search Saliou.  # your private domain
nameserver 192.168.12.77  # ns1 private IP address
' > /etc/resolvconf/resolv.conf.d/head

resolvconf -u
