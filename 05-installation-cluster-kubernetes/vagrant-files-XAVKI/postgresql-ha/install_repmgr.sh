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

#
#REPMGRD_ENABLED=yes
#REPMGRD_CONF="/etc/repmgr.conf"



# Variables ###################################################

POSTGRESQL_ROLE=$1
POSTGRESQL_VERSION=16
POSTGRESQL_VERSION_MINOR=16+257.pgdg22.04+1

# Functions ###################################################

install_repmgr(){
  apt install -qq -y repmgr
  sed -i '/127.0.2/d' /etc/hosts

echo "REPMGRD_ENABLED=yes
REPMGRD_CONF="/etc/repmgr.conf"
REPMGRD_OPTS="--daemonize=false"
REPMGRD_USER=postgres
REPMGRD_BIN=/usr/bin/repmgrd
REPMGRD_PIDFILE=/var/run/repmgrd.pid
" > /etc/default/repmgrd
  systemctl daemon-reload
  systemctl restart repmgrd
}

install_repmgr_master(){
  sudo -u postgres psql -c "CREATE ROLE replication REPLICATION LOGIN CONNECTION LIMIT 1 ENCRYPTED PASSWORD 'replication';"
  echo "host    replication     repmgr     127.0.0.1/32            trust" | tee -a /etc/postgresql/*/main/pg_hba.conf
  echo "host    repmgr          repmgr     127.0.0.1/32            trust" | tee -a /etc/postgresql/*/main/pg_hba.conf
  echo "host    replication     repmgr     127.0.2.1/32            trust" | tee -a /etc/postgresql/*/main/pg_hba.conf
  echo "host    repmgr          repmgr     127.0.2.1/32            trust" | tee -a /etc/postgresql/*/main/pg_hba.conf
  echo "host    replication     repmgr     192.168.12.0/24         trust" | tee -a /etc/postgresql/*/main/pg_hba.conf
  echo "host    repmgr          repmgr     192.168.12.0/24         trust" | tee -a /etc/postgresql/*/main/pg_hba.conf
  echo "host    all             Saliou      192.168.12.0/24         md5" | tee -a /etc/postgresql/*/main/pg_hba.conf
  echo > /etc/postgresql/${POSTGRESQL_VERSION}/main/conf.d/replication.conf
  echo "listen_addresses = '*'" | tee -a /etc/postgresql/${POSTGRESQL_VERSION}/main/conf.d/replication.conf
  echo "wal_level = replica" | tee -a /etc/postgresql/${POSTGRESQL_VERSION}/main/conf.d/replication.conf
  echo "wal_log_hints = on" | tee -a /etc/postgresql/${POSTGRESQL_VERSION}/main/conf.d/replication.conf
  echo "max_wal_senders = 100" | tee -a /etc/postgresql/${POSTGRESQL_VERSION}/main/conf.d/replication.conf
  echo "hot_standby = on" | tee -a /etc/postgresql/${POSTGRESQL_VERSION}/main/conf.d/replication.conf
  echo "shared_preload_libraries = 'repmgr'" | tee -a /etc/postgresql/${POSTGRESQL_VERSION}/main/conf.d/replication.conf
  echo "max_replication_slots = 10" | tee -a /etc/postgresql/${POSTGRESQL_VERSION}/main/conf.d/replication.conf
  echo "archive_mode = on" | tee -a /etc/postgresql/${POSTGRESQL_VERSION}/main/conf.d/replication.conf
  echo "archive_command = '/bin/true'" | tee -a /etc/postgresql/${POSTGRESQL_VERSION}/main/conf.d/replication.conf
  systemctl restart postgresql
  sudo -u postgres psql -c "CREATE USER repmgr SUPERUSER;"  
  sudo -u postgres psql -c "CREATE DATABASE repmgr WITH OWNER repmgr;"

echo "
node_id=1
node_name=$(hostname)
conninfo='host=$(hostname) user=repmgr dbname=repmgr connect_timeout=2'
data_directory='/var/lib/postgresql/${POSTGRESQL_VERSION}/main'
monitoring_history=yes
reconnect_attempts=1
reconnect_interval=1
failover=automatic
use_replication_slots=yes 
promote_command='/usr/bin/repmgr standby promote -f /etc/repmgr.conf --log-to-file'
follow_command='/usr/bin/repmgr standby follow -f /etc/repmgr.conf --log-to-file --upstream-node-id=%n'
log_file='/var/log/postgresql/repmgr.log'
log_level=INFO
" > /etc/repmgr.conf
sleep 10
systemctl restart repmgrd
su - postgres -c "/usr/bin/repmgr primary register --force"
su - postgres -c "/usr/bin/repmgr cluster show"
}

install_repmgr_worker(){
  sudo -u postgres psql -c "CREATE ROLE replication REPLICATION LOGIN CONNECTION LIMIT 1 ENCRYPTED PASSWORD 'replication';"
  echo "host    replication     repmgr     127.0.0.1/32            trust" | tee -a /etc/postgresql/*/main/pg_hba.conf
  echo "host    repmgr          repmgr     127.0.0.1/32            trust" | tee -a /etc/postgresql/*/main/pg_hba.conf
  echo "host    replication     repmgr     127.0.2.1/32            trust" | tee -a /etc/postgresql/*/main/pg_hba.conf
  echo "host    repmgr          repmgr     127.0.2.1/32            trust" | tee -a /etc/postgresql/*/main/pg_hba.conf
  echo "host    replication     repmgr     192.168.12.0/24         trust" | tee -a /etc/postgresql/*/main/pg_hba.conf
  echo "host    repmgr          repmgr     192.168.12.0/24         trust" | tee -a /etc/postgresql/*/main/pg_hba.conf
  echo "host    all             Saliou      192.168.12.0/24         md5" | tee -a /etc/postgresql/*/main/pg_hba.conf
  echo > /etc/postgresql/${POSTGRESQL_VERSION}/main/conf.d/replication.conf
  echo "listen_addresses = '*'" | tee -a /etc/postgresql/${POSTGRESQL_VERSION}/main/conf.d/replication.conf
  echo "wal_level = replica" | tee -a /etc/postgresql/${POSTGRESQL_VERSION}/main/conf.d/replication.conf
  echo "wal_log_hints = on" | tee -a /etc/postgresql/${POSTGRESQL_VERSION}/main/conf.d/replication.conf
  echo "max_wal_senders = 100" | tee -a /etc/postgresql/${POSTGRESQL_VERSION}/main/conf.d/replication.conf
  echo "hot_standby = on" | tee -a /etc/postgresql/${POSTGRESQL_VERSION}/main/conf.d/replication.conf
  echo "max_replication_slots = 10" | tee -a /etc/postgresql/${POSTGRESQL_VERSION}/main/conf.d/replication.conf
  echo "shared_preload_libraries = 'repmgr'" | tee -a /etc/postgresql/${POSTGRESQL_VERSION}/main/conf.d/replication.conf
  echo "archive_mode = on" | tee -a /etc/postgresql/${POSTGRESQL_VERSION}/main/conf.d/replication.conf
  echo "archive_command = '/bin/true'" | tee -a /etc/postgresql/${POSTGRESQL_VERSION}/main/conf.d/replication.conf

  #worker
echo "
node_id=2
node_name=$(hostname)
conninfo='host=$(hostname) user=repmgr dbname=repmgr connect_timeout=2'
data_directory='/var/lib/postgresql/${POSTGRESQL_VERSION}/main'
monitoring_history=yes
reconnect_attempts=1
reconnect_interval=1
failover=automatic
use_replication_slots=yes
promote_command='/usr/bin/repmgr standby promote -f /etc/repmgr.conf --log-to-file'
follow_command='/usr/bin/repmgr standby follow -f /etc/repmgr.conf --log-to-file --upstream-node-id=%n'
log_file='/var/log/postgresql/repmgr.log'
log_level=INFO
" > /etc/repmgr.conf
systemctl stop postgresql
rm -rf /var/lib/postgresql/*/main/*
su - postgres -c "/usr/bin/repmgr -h pgmaster1 -U repmgr -d repmgr standby clone"
systemctl start postgresql
su - postgres -c "/usr/bin/repmgr -h pgmaster1 -U repmgr -d repmgr standby register"
systemctl restart repmgrd
}

# Let's Go !! #################################################

install_repmgr

if [[ "$POSTGRESQL_ROLE" == "master" ]];then
  install_repmgr_master
else
  install_repmgr_worker
fi

## Notes ######################################################

## to check settings
#
# select * from pg_settings where name like '%wal%';