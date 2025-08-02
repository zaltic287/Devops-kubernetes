#!/bin/bash

## install postgresql


IP=$(hostname -I | awk '{print $2}')
echo "START - install postgresql "$IP


echo "[1]: install postgresql"

apt install -qq -y postgresql 2>&1 >/dev/null
pg_ctlcluster 13 main start

echo "listen_addresses = '0.0.0.0'" >> /etc/postgresql/13/main/postgresql.conf
echo "host    cryptoslist     cryptos         192.168.13.0/24         md5" >> /etc/postgresql/13/main/pg_hba.conf

systemctl restart postgresql

sudo -u postgres psql -c "create database cryptoslist;"
sudo -u postgres psql -c "create user cryptos with password 'password';"
sudo -u postgres psql -c "grant ALL privileges on database cryptoslist to cryptos;"
