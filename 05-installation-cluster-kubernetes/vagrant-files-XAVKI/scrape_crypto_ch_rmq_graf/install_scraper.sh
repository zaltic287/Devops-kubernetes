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
# create queues and exchange
###############################################################



# Variables ###################################################



# Functions ###################################################



# Let's Go !! #################################################

mkdir -p /opt/app/{golang,python}
chown vagrant -R /opt/app

wget -q https://chromedriver.storage.googleapis.com/112.0.5615.49/chromedriver_linux64.zip
unzip chromedriver_linux64.zip
mv chromedriver /usr/local/bin/
apt install -y -qq python3-pip chromium
pip install selenium pika pyyaml python-json-logger

cp /vagrant/python/scrape.py /opt/app/python/
cp /vagrant/python/config.yml /opt/app/python/

cp /vagrant/golang/cryptos_scrape /opt/app/golang/
cp /vagrant/golang/config.yml /opt/app/golang/

chmod -R +x /opt/app/
chown -R vagrant /opt/app/
