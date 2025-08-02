#!/usr/bin/bash



# Functions

install_postgresql_start(){

apt install -qq -y postgresql 2>&1 >/dev/null
pg_ctlcluster 14 main start

}

create_user_database(){

sudo -u postgres psql -c "create database zabbix;"
sudo -u postgres psql -c "create user zabbix with password 'password';"
sudo -u postgres psql -c "grant ALL privileges on database zabbix to zabbix;"

}

configure_postgresql(){

echo "listen_addresses = '*'" >> /etc/postgresql/14/main/postgresql.conf
echo "host    zabbix     all             192.168.0.1/16            md5" >> /etc/postgresql/14/main/pg_hba.conf

}


restart_postgresql(){

systemctl restart postgresql

}

# Let's Go

install_postgresql_start
create_user_database
configure_postgresql
restart_postgresql