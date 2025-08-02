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

VERSION=1.96.0
IP=$(hostname -I | awk '{print $2}')

# Functions ###################################################

victoria_metrics_install(){

wget -qq https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v${VERSION}/victoria-metrics-linux-amd64-v${VERSION}.tar.gz
tar xzf victoria-metrics-linux-amd64-v${VERSION}.tar.gz -C /usr/local/bin/
chmod +x /usr/local/bin/victoria-metrics-prod

groupadd --system victoriametrics
useradd -s /sbin/nologin --system -g victoriametrics victoriametrics

mkdir -p /var/lib/victoriametrics/ /etc/victoriametrics/
chown victoriametrics:victoriametrics /var/lib/victoriametrics/ /etc/victoriametrics/

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
       -storageDataPath=/var/lib/victoriametrics/ \
       -httpListenAddr=0.0.0.0:8428 \
       -retentionPeriod=1 \
       -promscrape.config=/etc/victoriametrics/scrape.yml \
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

victoria_metrics_configuration(){
echo "
global:
  external_labels:
    youtube: 'Saliou'
scrape_configs:
  - job_name: node_exporter
    static_configs:
      - targets: 
" > /etc/victoriametrics/scrape.yml
awk '$1 ~ "^192.168" {print "        - "$2":9100"}' /etc/hosts >> /etc/victoriametrics/scrape.yml

echo "
  - job_name: clickhouse_metrics
    static_configs:
      - targets:" >> /etc/victoriametrics/scrape.yml

awk '$2 ~ "clickhouse" {print "        - "$2":9363"}' /etc/hosts >> /etc/victoriametrics/scrape.yml

}


victoria_metrics_test(){

curl http://localhost:8428/api/v1/query -d 'query={job=~".*"}'

}

victoria_metrics_restart(){
  systemctl restart victoriametrics
  systemctl enable victoriametrics
}

grafana_install(){
apt install gnupg2 curl software-properties-common dirmngr apt-transport-https lsb-release ca-certificates
wget -q -O /usr/share/keyrings/grafana.key https://apt.grafana.com/gpg.key
echo "deb [signed-by=/usr/share/keyrings/grafana.key] https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
apt-get update -qq >/dev/null
apt-get install -qq -y grafana >/dev/null
}

grafana_dashboard(){
wget https://raw.githubusercontent.com/rfrail3/grafana-dashboards/master/prometheus/node-exporter-full.json -P /var/lib/grafana/

echo "
apiVersion: 1
providers:
- name: 'node-exporter'
  orgId: 1
  folder: ''
  type: file
  disableDeletion: false
  updateIntervalSeconds: 10 
  options:
    path: /var/lib/grafana/node-exporter-full.json
" > /etc/grafana/provisioning/dashboards/dashboard-node-exporter.yml
chown -R root:grafana /etc/grafana/provisioning/dashboards/dashboard-node-exporter.yml

wget https://raw.githubusercontent.com/weastur/grafana-dashboards/main/dashboards/clickhouse/clickhouse.json -P /var/lib/grafana/

echo "
apiVersion: 1
providers:
- name: 'clickhouse-exporter'
  orgId: 1
  folder: ''
  type: file
  disableDeletion: false
  updateIntervalSeconds: 10 
  options:
    path: /var/lib/grafana/clickhouse.json
" > /etc/grafana/provisioning/dashboards/dashboard-clickhouse-exporter.yml

sed -i s/'${DS_PROMETHEUS}'/'prometheus'/g /var/lib/grafana/clickhouse.json

}

grafana_edit_configuration()
{
echo "
datasources:
-  access: 'proxy'
   editable: true 
   is_default: true
   name: 'prometheus'
   org_id: 1 
   type: 'prometheus' 
   url: 'http://"$IP":8428' 
   version: 1
" > /etc/grafana/provisioning/datasources/all.yml
sudo chmod 644 /etc/grafana/provisioning/datasources/all.yml
}

grafana_restart(){
systemctl start grafana-server
systemctl enable grafana-server
}


# Let's Go !! #################################################

victoria_metrics_install
victoria_metrics_systemd_service
victoria_metrics_configuration
victoria_metrics_restart
victoria_metrics_test

grafana_install
grafana_edit_configuration
grafana_dashboard
grafana_restart

