#!/bin/bash

## install nomad worker

## Variables #################################################

IP=$(hostname -I | awk '{print $2}')

VERSION=1.6.1

if [[ "$1" == "withoutconsul" ]];then

SERVER='servers = ["nomad1","nomad2","nomad3"]'
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

#consul {
#  address = "'${IP}':8500"
#}

client {
  enabled = true
  network_interface = "eth1"
  '${SERVER}'
  '${JOIN}'
}

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

}

## Let's go  #################################################

install_nomad_archive
install_nomad_dir_user
install_nomad_config
install_nomad_systemd
start_nomad
