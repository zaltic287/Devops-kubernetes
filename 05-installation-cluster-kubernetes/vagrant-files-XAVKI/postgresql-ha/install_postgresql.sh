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

POSTGRESQL_VERSION=16
POSTGRESQL_VERSION_MINOR=16+257.pgdg22.04+1

# Functions ###################################################

install_postgresql(){
  wget -q -O- https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor > /etc/apt/trusted.gpg.d/signal-desktop-keyring.gpg
  echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" | tee -a /etc/apt/sources.list.d/pgdg.list
  apt update -qq 2>&1 > /dev/null
  #apt install -y -qq postgresql=${POSTGRESQL_VERSION_MINOR} postgresql-contrib 2>&1 > /dev/null
  apt install -y -qq postgresql postgresql-contrib 2>&1 > /dev/null
}

# Let's Go !! #################################################

install_postgresql
