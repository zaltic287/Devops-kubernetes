#!/usr/bin/bash

###############################################################
#  TITRE: install vm/grafana
#
#  AUTEUR:   Xavier
#  VERSION: 1.0
#  CREATION:  13/06/2023
#
#  DESCRIPTION: 
###############################################################

set -euo pipefail

# Variables ###################################################

VERSION=1.96.0
IP=$(hostname -I | awk '{print $2}')

# Functions ###################################################

victoria_metrics_install(){

wget -qq https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v${VERSION}/victoria-metrics-linux-amd64-v${VERSION}.tar.gz
tar xzf victoria-metrics-linux-amd64-v${VERSION}.tar.gz -C /usr/local/bin/
chmod +x /usr/local/bin/victoria-metrics-prod

groupadd --system victoriametrics
useradd -s /sbin/nologin --system -g victoriametrics victoriametrics

mkdir -p /var/lib/victoria-metrics/
chown victoriametrics:victoriametrics /var/lib/victoria-metrics/

}

victoria_metrics_systemd_service(){
echo "
[Unit]
Description=Description=VictoriaMetrics service
After=network.target

[Service]
Type=simple
LimitNOFILE=2097152
User=victoriametrics
Group=victoriametrics
ExecStart=/usr/local/bin/victoria-metrics-prod \
       -storageDataPath=/var/lib/victoria-metrics/ \
       -httpListenAddr=0.0.0.0:8428 \
       -retentionPeriod=1 \
       -selfScrapeInterval=10s

SyslogIdentifier=victoriametrics
Restart=always

PrivateTmp=yes
ProtectHome=yes
NoNewPrivileges=yes
ProtectSystem=full

[Install]
WantedBy=multi-user.target
" >/etc/systemd/system/victoriametrics.service
}

victoria_metrics_test(){

curl http://localhost:8428/api/v1/query -d 'query={job=~".*"}'

}

victoria_metrics_restart(){
  systemctl restart victoriametrics
  systemctl enable victoriametrics
}

# Let's Go !! #################################################

victoria_metrics_install
victoria_metrics_systemd_service
victoria_metrics_restart
victoria_metrics_test

