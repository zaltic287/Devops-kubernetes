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

POSTGRESQL_ROLE=$1
POSTGRESQL_VERSION=16
POSTGRESQL_VERSION_MINOR=16+257.pgdg22.04+1

# Functions ###################################################

install_replication_master(){
  sudo -u postgres psql -c "CREATE ROLE replication REPLICATION LOGIN CONNECTION LIMIT 1 ENCRYPTED PASSWORD 'replication';"
  echo "host    replication     replication     192.168.12.0/24         md5" | tee -a /etc/postgresql/*/main/pg_hba.conf
  echo "host    all           Saliou           192.168.12.0/24         md5" | tee -a /etc/postgresql/*/main/pg_hba.conf
  echo > /etc/postgresql/${POSTGRESQL_VERSION}/main/conf.d/replication.conf
  echo "listen_addresses = '*'" | tee -a /etc/postgresql/${POSTGRESQL_VERSION}/main/conf.d/replication.conf
  echo "wal_level = replica" | tee -a /etc/postgresql/${POSTGRESQL_VERSION}/main/conf.d/replication.conf
  echo "wal_log_hints = on" | tee -a /etc/postgresql/${POSTGRESQL_VERSION}/main/conf.d/replication.conf
  echo "max_wal_senders = 100" | tee -a /etc/postgresql/${POSTGRESQL_VERSION}/main/conf.d/replication.conf
  echo "hot_standby = on" | tee -a /etc/postgresql/${POSTGRESQL_VERSION}/main/conf.d/replication.conf
  systemctl restart postgresql
}

install_replication_worker(){
  sudo -u postgres psql -c "CREATE ROLE replication REPLICATION LOGIN CONNECTION LIMIT 1 ENCRYPTED PASSWORD 'replication';"
  echo "host    replication     replication     192.168.12.0/24         md5" | tee -a /etc/postgresql/*/main/pg_hba.conf
  echo "host    all           Saliou           192.168.12.0/24         md5" | tee -a /etc/postgresql/*/main/pg_hba.conf
  echo > /etc/postgresql/${POSTGRESQL_VERSION}/main/conf.d/replication.conf
  echo "listen_addresses = '*'" | tee -a /etc/postgresql/${POSTGRESQL_VERSION}/main/conf.d/replication.conf
  echo "wal_level = replica" | tee -a /etc/postgresql/${POSTGRESQL_VERSION}/main/conf.d/replication.conf
  echo "wal_log_hints = on" | tee -a /etc/postgresql/${POSTGRESQL_VERSION}/main/conf.d/replication.conf
  echo "max_wal_senders = 100" | tee -a /etc/postgresql/${POSTGRESQL_VERSION}/main/conf.d/replication.conf
  echo "hot_standby = on" | tee -a /etc/postgresql/${POSTGRESQL_VERSION}/main/conf.d/replication.conf
  
  #worker
  systemctl stop postgresql
  rm -rf /var/lib/postgresql/*/main/*
  sudo -u postgres PGPASSWORD=replication pg_basebackup -h pgmaster1 -D /var/lib/postgresql/${POSTGRESQL_VERSION}/main/ -P -U replication --wal-method=fetch
  touch /var/lib/postgresql/16/main/standby.signal
  echo "primary_conninfo = 'host=pgmaster1 port=5432 user=replication password=replication'" | tee -a /etc/postgresql/${POSTGRESQL_VERSION}/main/conf.d/replication.conf
  echo "data_sync_retry = on" | tee -a /etc/postgresql/${POSTGRESQL_VERSION}/main/conf.d/replication.conf  
  systemctl restart postgresql
}


#create_objects(){
#  sudo -u postgres psql -c "CREATE ROLE Saliou LOGIN ENCRYPTED PASSWORD 'password';"  
#  sudo -u postgres psql -c "CREATE DATABASE db_ha;"
#  sudo -u postgres psql -d db_ha -c "CREATE SCHEMA sch_ha;"
#  sudo -u postgres psql -c "GRANT CONNECT ON DATABASE db_ha TO Saliou;"
#  sudo -u postgres psql -c "GRANT CONNECT ON DATABASE db_ha TO replication;"
#  sudo -u postgres psql -c "GRANT USAGE ON SCHEMA sch_ha TO Saliou;"
#  sudo -u postgres psql -c "GRANT USAGE ON SCHEMA sch_ha TO replication;"
#  sudo -u postgres psql -d db_ha -c "CREATE TABLE sch_ha.tb1 (f1 int, f2 varchar(255));"
#  sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE db_ha TO Saliou;"
#  sudo -u postgres psql -d db_ha -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA sch_ha TO Saliou;"
#  sudo -u postgres psql -d db_ha -c "GRANT SELECT ON ALL TABLES IN SCHEMA sch_ha TO replication;"
#}


# Let's Go !! #################################################

if [[ "$POSTGRESQL_ROLE" == "master" ]];then
  install_replication_master
else
  install_replication_worker
fi

## Notes ######################################################

## to check settings
#
# select * from pg_settings where name like '%wal%';