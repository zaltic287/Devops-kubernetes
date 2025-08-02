#!/bin/bash

## install master consul

IP=$(hostname -I | awk '{print $2}')
IP_CMASTER=$(awk '$2 ~ "oth4" {print $1}' /etc/hosts)
echo "START - install consul - "$IP

echo "[1]: install utils"
apt-get update -qq >/dev/null
apt-get install -qq -y wget unzip dnsutils >/dev/null

echo "[2]: install consul"
wget -q https://releases.hashicorp.com/consul/1.10.3/consul_1.10.3_linux_amd64.zip
unzip /home/vagrant/consul_1.10.3_linux_amd64.zip
mv /home/vagrant/consul /usr/local/bin/

echo "[3]: create user/group and directory"
groupadd --system consul
useradd -s /sbin/nologin --system -g consul consul
mkdir -p /var/lib/consul
chown -R consul:consul /var/lib/consul
chmod -R 775 /var/lib/consul
mkdir /etc/consul.d
chown -R consul:consul /etc/consul.d

echo "consul configuration for master"

if [[ $1 == "consul_master" ]];then
echo '{
    "advertise_addr": "'$IP'",
    "bind_addr": "'$IP'",
    "bootstrap_expect": 1,
    "client_addr": "0.0.0.0",
    "datacenter": "mydc",
    "data_dir": "/var/lib/consul",
    "domain": "consul",
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
        "'$IP'"
    ],
    "server": true,
    "start_join": [
        "'$IP'"
    ],
    "ui": true
}' > /etc/consul.d/config.json

echo "install consul as dns"

apt install -y -qq dnsmasq

systemctl stop systemd-resolved.service

echo '
server=/.consul/127.0.0.1#8600
server=1.1.1.1
' > /etc/dnsmasq.d/10-consul.conf

systemctl restart dnsmasq

echo '
nameserver 127.0.0.1
'>/etc/resolv.conf

fi

if [[ $1 == "consul_agent" ]];then
echo '{
    "advertise_addr": "'$IP'",
    "bind_addr": "'$IP'",
    "client_addr": "0.0.0.0",
    "datacenter": "mydc",
    "data_dir": "/var/lib/consul",
    "domain": "consul",
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
    "'$IP_CMASTER'"
    ]
}' > /etc/consul.d/config.json
fi

echo "consul create service systemd"
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

echo "consul start service"
systemctl enable consul
service consul start



if [[ $2 == "yes" ]];then

echo "install consul services"
echo '
{"service":
 {
  "name": "rabbitmq-gui", 
  "tags": ["rabbitmq","gui"], 
  "port": 15672,
  "check": {
    "tcp": "127.0.0.1:15672",
    "interval": "3s"
  }
 }
}' > /etc/consul.d/rabbitmq-gui.json
 
echo '
{"service":
 {
  "name": "rabbitmq", 
  "tags": ["rabbitmq","data"], 
  "port": 5672,
  "check": {
    "tcp": "127.0.0.1:5672",
    "interval": "3s"
  }
 }
}' > /etc/consul.d/rabbitmq-data.json

sleep 5s

consul reload

fi
