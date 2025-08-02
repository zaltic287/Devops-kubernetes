#!/bin/bash

## install consul master

## Variables #################################################

IP=$(hostname -I | awk '{print $2}')

VERSION=1.16.1

if [[ $(hostname) == "nomad1" ]];then 
	BOOTSTRAP_EXPECTED=1	
else
	BOOTSTRAP_EXPECTED=3
fi


## Functions #################################################

install_prerequisites(){

apt-get update -qq >/dev/null
apt-get install -qq -y wget unzip dnsutils >/dev/null

}

install_consul_archive(){

wget -q https://releases.hashicorp.com/consul/${VERSION}/consul_${VERSION}_linux_amd64.zip
unzip /home/vagrant/consul_${VERSION}_linux_amd64.zip
mv /home/vagrant/consul /usr/local/bin/
chmod +x -R /usr/local/bin/

}

install_consul_dir_user(){

groupadd --system consul
useradd -s /sbin/nologin --system -g consul consul
mkdir -p /var/lib/consul
chown -R consul:consul /var/lib/consul
chmod -R 750 /var/lib/consul
mkdir /etc/consul.d
chown -R consul:consul /etc/consul.d

}

install_consul_config(){

echo '{
    "advertise_addr": "'${IP}'",
    "bind_addr": "'${IP}'",
    "bootstrap_expect": '${BOOTSTRAP_EXPECTED}',
    "client_addr": "0.0.0.0",
    "datacenter": "Saliou",
    "data_dir": "/var/lib/consul",
    "domain": "Saliou",
    "enable_script_checks": true,
    "dns_config": {
        "enable_truncate": true,
        "only_passing": true
    },
    "enable_syslog": true,
    "leave_on_terminate": true,
    "log_level": "INFO",
    "rejoin_after_leave": true,
    "retry_join": [
        "nomad1",
        "nomad2",
        "nomad3"
    ],
    "server": true,
    "ui": true
}' > /etc/consul.d/config.json

}

install_consul_systemd(){

echo '[Unit]
Description=Consul Service Discovery Agent
Documentation=https://www.consul.io/
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=consul
Group=consul
ExecStart=/usr/local/bin/consul agent \
  -node='$IP' \
  -config-dir=/etc/consul.d

ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT
TimeoutStopSec=5
Restart=on-failure
SyslogIdentifier=consul

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/consul.service

}

start_consul(){

systemctl enable consul
service consul start

}

## Let's go  #################################################

install_prerequisites
install_consul_archive
install_consul_dir_user
install_consul_config
install_consul_systemd
start_consul
