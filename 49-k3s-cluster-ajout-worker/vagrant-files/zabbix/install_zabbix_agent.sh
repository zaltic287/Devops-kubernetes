#!/usr/bin/bash

############################################
#
#   Install ZABBIX Agent
#
############################################


# Variables

VERSION=6.0-4

# Functions

install_zabbix_repository(){

wget -q https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_${VERSION}+ubuntu22.04_all.deb  
dpkg -i zabbix-release_${VERSION}+ubuntu22.04_all.deb 
apt update -qq 2>&1 >/dev/null

}

install_zabbix_agent(){

apt install -y -qq zabbix-agent 

}

configure_zabbix_agent(){

sed -i s/"Server=.*"/"Server=zabbix1"/g /etc/zabbix/zabbix_agentd.conf
sed -i s/"ServerActive=.*"/"ServerActive="/g /etc/zabbix/zabbix_agentd.conf
sed -i s/"Hostname=.*"/"Hostname=z2"/g /etc/zabbix/zabbix_agentd.conf

}

enable_restart_zabbix_agent(){

systemctl restart zabbix-agent
systemctl enable zabbix-agent

}

# Let's Go

install_zabbix_repository
install_zabbix_agent
configure_zabbix_agent
enable_restart_zabbix_agent