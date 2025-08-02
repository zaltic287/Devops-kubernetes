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

ANSIBLE_HOST_KEY_CHECKING=False 

# Functions ###################################################



# Let's Go !! #################################################

#ansible -i inventory.yml all -u vagrant -k -m ping

ansible-playbook -i inventory.yml -u vagrant -k playbook.yml
