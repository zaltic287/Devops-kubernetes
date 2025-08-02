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


install_prerequisites(){

apt upgrade -y python3 && apt install -y python3-venv
python3 -m venv gapp
source /home/vagrant/gapp/bin/activate && cd /home/vagrant/gapp/
pip install gremlinpython==3.4.6 fastapi uvicorn jinja2 aiofiles
mkdir templates static

}

install_app(){
cp /vagrant/main.py /home/vagrant/gapp/
cp /vagrant/run.sh /home/vagrant/gapp/
}

# Let's Go !! #################################################

install_prerequisites
install_app
