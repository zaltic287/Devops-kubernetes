#!/bin/bash

## install nomad master

## Variables #################################################

IP=$(hostname -I | awk '{print $2}')

VERSION=1.6.1

BOOTSTRAP_EXPECTED=3

if [[ "$1" == "withoutconsul" ]];then

  if [[ $(hostname) == "nomad1" ]];then 
    BOOTSTRAP_EXPECTED=1	
  fi

JOIN='
	server_join {
    retry_join = ["nomad1:4648","nomad2:4648","nomad3:4648"]
  }
'

fi


## Functions #################################################


install_nomad_archive(){
wget -q https://releases.hashicorp.com/nomad/${VERSION}/nomad_${VERSION}_linux_amd64.zip
unzip /home/vagrant/nomad_${VERSION}_linux_amd64.zip
mv /home/vagrant/nomad /usr/local/bin/
chmod +x -R /usr/local/bin/

}

install_nomad_dir_user(){

mkdir -p /var/lib/nomad
chmod -R 700 /var/lib/nomad
mkdir -p /etc/nomad.d

}

install_nomad_config(){

echo '
datacenter = "Saliou"
data_dir = "/var/lib/nomad"
bind_addr = "'${IP}'"


server {
  enabled = true
  bootstrap_expect = '${BOOTSTRAP_EXPECTED}'
  '${JOIN}'
}

telemetry {
  collection_interval = "1s"
  disable_hostname = true
  prometheus_metrics = true
  publish_allocation_metrics = true
  publish_node_metrics = true
}

#client {
#  enabled = true
#  servers = ["'${IP}'"]
#}

' > /etc/nomad.d/nomad.hcl

}

install_nomad_systemd(){

echo '[Unit]
Description=Nomad
Documentation=https://www.nomadproject.io/docs
Wants=network-online.target
After=network-online.target

[Service]
ExecReload=/bin/kill -HUP $MAINPID
ExecStart=/usr/local/bin/nomad agent -config /etc/nomad.d
KillMode=process
KillSignal=SIGINT
LimitNOFILE=infinity
LimitNPROC=infinity
Restart=on-failure
RestartSec=2
StartLimitBurst=3
StartLimitIntervalSec=10
TasksMax=infinity

[Install]
WantedBy=multi-user.target

' > /etc/systemd/system/nomad.service

}

start_nomad(){

systemctl enable nomad
systemctl start nomad
echo 'export NOMAD_ADDR=http://'${IP}':4646' >> /etc/profile.d/nomad.sh
}

## Let's go  #################################################

install_nomad_archive
install_nomad_dir_user
install_nomad_config
install_nomad_systemd
start_nomad
