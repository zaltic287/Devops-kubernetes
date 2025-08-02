#!/bin/bash

############################################
#
#   Install ZABBIX Server
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

install_zabbix_server(){

apt install -y -qq zabbix-server-pgsql zabbix-frontend-php php8.1-pgsql zabbix-nginx-conf zabbix-sql-scripts zabbix-agent postgresql-client

}

initialize_database(){

zcat /usr/share/zabbix-sql-scripts/postgresql/server.sql.gz | PGPASSWORD="password" psql -h zpg1 -U zabbix zabbix

}

configure_zabbix_server(){

sed -i s/"#.*server_name.*"/"        server_name zabbix.Saliou; "/g /etc/zabbix/nginx.conf
echo "DBPassword=password" >> /etc/zabbix/zabbix_server.conf
echo "DBHost=zpg1" >> /etc/zabbix/zabbix_server.conf

cp /vagrant/zabbix.conf.php /etc/zabbix/web/zabbix.conf.php
chown www-data:www-data /etc/zabbix/web/zabbix.conf.php

}

enable_restart_zabbix_server(){

systemctl restart zabbix-server zabbix-agent nginx php8.1-fpm
systemctl enable zabbix-server zabbix-agent nginx php8.1-fpm

}

# Let's Go

install_zabbix_repository
install_zabbix_server
initialize_database
configure_zabbix_server
enable_restart_zabbix_server