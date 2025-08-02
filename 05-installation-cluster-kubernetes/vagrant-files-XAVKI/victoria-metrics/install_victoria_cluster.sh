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

set -euo pipefail

# Variables ###################################################

VERSION="1.96.0"
IP=$(hostname -I | awk '{print $2}')
VICTORIA_STORAGE="/var/lib/victoria-metrics/"


# Functions ###################################################

victoria_metrics_cluster_install(){

wget -qq https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v${VERSION}/victoria-metrics-linux-amd64-v${VERSION}-cluster.tar.gz
tar xzf victoria-metrics-linux-amd64-v${VERSION}-cluster.tar.gz -C /usr/local/bin/

wget -qq https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v${VERSION}/vmutils-linux-amd64-v${VERSION}.tar.gz
tar xzf vmutils-linux-amd64-v${VERSION}.tar.gz -C /usr/local/bin/
chmod -R +x /usr/local/bin/

chmod +x /usr/local/bin/*

groupadd --system victoriametrics
useradd -s /sbin/nologin --system -g victoriametrics victoriametrics

mkdir -p ${VICTORIA_STORAGE}
chown victoriametrics:victoriametrics ${VICTORIA_STORAGE}

}

vminsert_systemd_service(){

echo "
[Unit]
Description=vminsert systemd service.
After=network.target

[Service]
User=victoriametrics
Type=simple
ExecStart=/usr/local/bin/vminsert-prod -storageNode=vic1:8400,vic2:8400,vic3:8400 -replicationFactor=2 -httpListenAddr=${IP}:8480

Restart=on-failure
#StandardOutput=/var/log/vminserter/vminserter.log
RestartSec=10s

[Install]
WantedBy=multi-user.target
">/etc/systemd/system/vminsert.service

}

vmselect_systemd_service(){

echo "

[Unit]
Description=vmselect systemd service.
After=network.target

[Service]
User=victoriametrics
Type=simple
ExecStart=/usr/local/bin/vmselect-prod -dedup.minScrapeInterval=30s -storageNode=vic1:8401,vic2:8401,vic3:8401 -replicationFactor=2 -httpListenAddr=${IP}:8481

Restart=on-failure
#StandardOutput=/var/log/vmselect/vmselect.log
RestartSec=10s

[Install]
WantedBy=multi-user.target
">/etc/systemd/system/vmselect.service

}

vmstorage_systemd_service(){

echo "

[Unit]
Description=vmstorage systemd service.
After=network.target

[Service]
User=victoriametrics
Type=simple
ExecStart=/usr/local/bin/vmstorage-prod -dedup.minScrapeInterval=30s -storageDataPath=${VICTORIA_STORAGE} -retentionPeriod 1y -httpListenAddr ${IP}:8482 -vminsertAddr=$(hostname):8400 -vmselectAddr=$(hostname):8401

Restart=on-failure
#StandardOutput=/var/log/vmstorage/vmstorage.log
RestartSec=5s

[Install]
WantedBy=multi-user.target

">/etc/systemd/system/vmstorage.service

}

victoria_metrics_restart(){
  systemctl restart vminsert
  systemctl enable vminsert

  systemctl restart vmselect
  systemctl enable vmselect

  sleep 20s

  systemctl restart vmstorage
  systemctl enable vmstorage
}

# Let's Go !! #################################################

victoria_metrics_cluster_install
vminsert_systemd_service
vmselect_systemd_service
vmstorage_systemd_service
victoria_metrics_restart
