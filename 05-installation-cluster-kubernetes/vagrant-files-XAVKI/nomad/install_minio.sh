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



# Functions ###################################################

install_deb_package(){

wget https://dl.min.io/server/minio/release/linux-amd64/archive/minio_20230831153116.0.0_amd64.deb -O minio.deb
dpkg -i minio.deb

}

install_systemd_service(){

echo '
[Unit]
Description=MinIO
Documentation=https://min.io/docs/minio/linux/index.html
Wants=network-online.target
After=network-online.target
AssertFileIsExecutable=/usr/local/bin/minio

[Service]
WorkingDirectory=/usr/local

User=minio
Group=minio
ProtectProc=invisible

EnvironmentFile=-/etc/default/minio
ExecStartPre=/bin/bash -c "if [ -z \"${MINIO_VOLUMES}\" ]; then echo \"Variable MINIO_VOLUMES not set in /etc/default/minio\"; exit 1; fi"
ExecStart=/usr/local/bin/minio server $MINIO_OPTS $MINIO_VOLUMES

Restart=always
LimitNOFILE=65536
TasksMax=infinity

TimeoutStopSec=infinity
SendSIGKILL=no

[Install]
WantedBy=multi-user.target
' > /etc/systemd/system/minio

}

create_env_file(){

echo'
MINIO_ROOT_USER=Saliou
MINIO_ROOT_PASSWORD=password
MINIO_VOLUMES="/srv/data"

# to change the url
#MINIO_SERVER_URL="http://minio.example.net:9000"

' >/etc/default/minio

}

create_user_dir(){

mkdir -p /srv/minio
groupadd -r minio
useradd -M -r -g minio minio
chown minio-user:minio /srv/minio/

}

start_systemd(){

systemctl start minio
systemctl enable minio

}


# Let's Go !! #################################################

install_deb_package
install_systemd_service
create_env_file
create_user_dir
start_systemd

