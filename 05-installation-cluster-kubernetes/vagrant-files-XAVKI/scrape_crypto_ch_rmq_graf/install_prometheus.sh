#!/usr/bin/bash

###############################################################
#  TITRE: install prometheus/grafana
#
#  AUTEUR:   Xavier
#  VERSION: 1.0
#  CREATION:  23/04/2021
#
#  DESCRIPTION: 
###############################################################

#set -euxo pipefail

# Variables ###################################################

IP=$(hostname -I | awk '{print $2}')

# Functions ###################################################

prometheus_install(){
  sudo apt-get update -qq >/dev/null
  sudo apt-get install -qq -y wget unzip prometheus >/dev/null
}

prometheus_configuration(){
echo "
global:
  scrape_interval:     5s 
  evaluation_interval: 5s 
  external_labels:
    youtube: 'Saliou'
rule_files:
scrape_configs:
  - job_name: node_exporter
    static_configs:
      - targets: 
" > /etc/prometheus/prometheus.yml
awk '$1 ~ "^192.168" {print "        - "$2":9100"}' /etc/hosts >> /etc/prometheus/prometheus.yml

echo "
  - job_name: clickhouse_metrics
    static_configs:
      - targets:" >> /etc/prometheus/prometheus.yml

awk '$2 ~ "ch1" {print "        - "$2":9363"}' /etc/hosts >> /etc/prometheus/prometheus.yml

}

prometheus_restart(){
  systemctl restart prometheus
  systemctl enable prometheus
}

grafana_install(){
apt install gnupg2 curl software-properties-common dirmngr apt-transport-https lsb-release ca-certificates
wget -q -O /usr/share/keyrings/grafana.key https://apt.grafana.com/gpg.key
#add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
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
   url: 'http://"$IP":9090' 
   version: 1
" > /etc/grafana/provisioning/datasources/all.yml
sudo chmod 644 /etc/grafana/provisioning/datasources/all.yml
}

grafana_restart(){
systemctl restart grafana-server
systemctl enable grafana-server
}

grafana_clickhouse_plugin(){
	https://github.com/grafana/clickhouse-datasource/releases/download/v2.2.1/grafana-clickhouse-datasource-2.2.1.linux_amd64.zip
	mkdir -p /var/lib/grafana/plugins
	chown grafana:grafana /var/lib/grafana/plugins
	unzip grafana-clickhouse-datasource-2.2.1.linux_amd64.zip -d /var/lib/grafana/plugins/

}

# Let's Go !! #################################################

prometheus_install
prometheus_configuration
prometheus_restart
grafana_install
grafana_edit_configuration
grafana_dashboard
grafana_clickhouse_plugin
grafana_restart
