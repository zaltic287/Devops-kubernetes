#!/bin/bash


## Variables ##############################################

VERSION="7.6.1"
#VERSION="7.4.1"
IP=$(hostname -I | cut -d " " -f 2)


## Check root ############################################

sudo -n true
if [ $? -ne 0 ]
    then
        echo "This script requires user to have passwordless sudo access"
        exit
fi


## Functions ###########################################

dependency_check_deb() {
java -version
if [ $? -ne 0 ]
    then
        sudo apt install openjdk-11-jdk-headless -y
    elif [ "`java -version 2> /tmp/version && awk '/version/ { gsub(/"/, "", $NF); print ( $NF < 1.7 ) ? "YES" : "NO" }' /tmp/version`" == "YES" ]
        then
            sudo apt-get install java-11-openjdk-headless -y
fi
}

dependency_check_rpm() {
    java -version
    if [ $? -ne 0 ]
        then
				sudo yum install java-11-openjdk-headless.x86_64 -y
    fi
}

debian_elk() {
sudo apt install -y unzip
wget -qO - https://d3g5vo6xdbdb9a.cloudfront.net/GPG-KEY-opendistroforelasticsearch | sudo apt-key add -
echo "deb https://d3g5vo6xdbdb9a.cloudfront.net/apt stable main" | sudo tee -a   /etc/apt/sources.list.d/opendistroforelasticsearch.list
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-oss-7.8.0-amd64.deb
sudo dpkg -i elasticsearch-oss-7.8.0-amd64.deb
sudo apt-get update
sudo apt install -y opendistroforelasticsearch

}


## Exec ##################################

if [ "$(grep -Ei 'debian|buntu|mint' /etc/*release)" ]
    then
        echo " It's a Debian based system"
        dependency_check_deb
        debian_elk
else
    echo "This script doesn't support ELK installation on this OS."
fi
