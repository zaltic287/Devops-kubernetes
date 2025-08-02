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


git clone https://github.com/apache/superset.git
cd superset/
echo "clickhouse-connect" >> ./docker/requirements-local.txt
docker-compose -f docker-compose-non-dev.yml up -d
