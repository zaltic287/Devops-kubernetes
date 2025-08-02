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

IP=$(hostname -I | awk '{print $2}')

if [[ "$1" == "y" ]];then 
  VICTORIA_DNS="vmagent1:8427"
else
  VICTORIA_DNS="vic1:8428"
fi

# Functions ###################################################

grafana_install(){
wget -q -O - https://packages.grafana.com/gpg.key | apt-key add -
add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
apt-get update -qq >/dev/null
apt-get install -qq -y grafana >/dev/null
}


grafana_edit_configuration()
{
echo "
datasources:
-  access: 'proxy'
   editable: true 
   is_default: true
   name: 'victoriametrics'
   org_id: 1 
   type: 'prometheus' 
   url: 'http://${VICTORIA_DNS}/' 
   version: 1
" > /etc/grafana/provisioning/datasources/all.yml
sudo chown root:grafana /etc/grafana/provisioning/datasources/all.yml
sudo chmod 640 /etc/grafana/provisioning/datasources/all.yml
}

grafana_dashboard(){
wget https://raw.githubusercontent.com/rfrail3/grafana-dashboards/master/prometheus/node-exporter-full.json -P /var/lib/grafana/
wget https://raw.githubusercontent.com/VictoriaMetrics/VictoriaMetrics/cluster/dashboards/victoriametrics-cluster.json -P /var/lib/grafana/

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

echo "
apiVersion: 1
providers:
- name: 'victoriametrics'
  orgId: 1
  folder: ''
  type: file
  disableDeletion: false
  updateIntervalSeconds: 10 
  options:
    path: /var/lib/grafana/victoriametrics-cluster.json
" > /etc/grafana/provisioning/dashboards/victoriametrics-cluster.yml


chown -R root:grafana /etc/grafana/provisioning/dashboards/*

}

grafana_restart(){
systemctl start grafana-server
systemctl enable grafana-server
}

# Let's Go !! #################################################

grafana_install
grafana_edit_configuration
grafana_dashboard
grafana_restart
