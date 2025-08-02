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
VERSION_ALERTMANAGER=0.26.0
USER_APP="victoriametrics"
if [[ "$(hostname)" == "vmagent1" ]]; then
  ALERTMANAGER_PEER="vmagent2"
else
  ALERTMANAGER_PEER="vmagent1"
fi

if [[ "$1" == "y" ]];then 
  VM_DNS="127.0.0.1:8427"
else
  VM_DNS="vic1:8428"
fi

# Functions ###################################################

victoria_alert_install(){

wget -qq https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v${VERSION}/vmutils-linux-amd64-v${VERSION}.tar.gz
tar xzf vmutils-linux-amd64-v${VERSION}.tar.gz -C /usr/local/bin/
chmod -R +x /usr/local/bin/

groupadd --system ${USER_APP}
useradd -s /sbin/nologin --system -g ${USER_APP} ${USER_APP}

}

victoria_alert_dir(){

mkdir -p mkdir -p /etc/vmalert/
chown -R ${USER_APP}:${USER_APP} /etc/vmalert/

}

victoria_alert_systemd_service(){
echo "
[Unit]
Description=Description=VictoriaAlert service
After=network.target

[Service]
Type=simple
User=${USER_APP}
ExecStart=/usr/local/bin/vmalert-prod \
      -datasource.url=http://${VM_DNS}/ \
      -remoteRead.url=http://${VM_DNS}/ \
      -remoteWrite.url=http://${VM_DNS}/ \
      -notifier.url=http://vmagent1:9093 \
      -notifier.url=http://vmagent2:9093 \
      -rule=/etc/vmalert/*.yml \
      -external.url=http://graf1:3000

SyslogIdentifier=vmalert
Restart=always

[Install]
WantedBy=multi-user.target
" >/etc/systemd/system/vmalert.service
}

victoria_alert_rules(){
echo "
groups:
- name: node_exporter_alerts
  rules:
  - alert: HostHighCpuLoad
    expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode=\"idle\"}[2m])) * 100) > 80
    for: 0m
    labels:
      severity: warning
    annotations:
      summary: Host high CPU load (instance {{ \$labels.instance }})
      description: CPU load is > 80%\n  VALUE = {{ \$value }}
  - alert: Node down
    expr: up{job=\"node_exporter\"} == 0
    for: 2m
    labels:
      severity: warning
    annotations:
      title: Node {{ \$labels.instance }} is down
      description: Failed to scrape {{ \$labels.job }} on {{ \$labels.instance }} for more than 2 minutes. Node seems down.
" >> /etc/vmalert/node_exporter.yml

}

victoria_alert_restart(){
  systemctl restart vmalert
  systemctl enable vmalert
}

## AlertManager Cluster

alertmanager_create_user_dir(){

useradd --no-create-home --shell /bin/false alertmanager
mkdir -p /etc/alertmanager  /var/lib/alertmanager
chown -R alertmanager:alertmanager /var/lib/alertmanager/ /etc/alertmanager

}

alertmanager_install_binary(){

wget -q https://github.com/prometheus/alertmanager/releases/download/v${VERSION_ALERTMANAGER}/alertmanager-${VERSION_ALERTMANAGER}.linux-amd64.tar.gz
tar xzf alertmanager-${VERSION_ALERTMANAGER}.linux-amd64.tar.gz
cp alertmanager-${VERSION_ALERTMANAGER}.linux-amd64/alertmanager /usr/local/bin/
cp alertmanager-${VERSION_ALERTMANAGER}.linux-amd64/amtool /usr/local/bin/
chmod +x /usr/local/bin/*

}

alertmanager_configuration_file(){

echo "
global:
  resolve_timeout: 2m
  smtp_require_tls: false

route:
  group_by: ['instance', 'severity']
  group_wait: 10s		# temps d'attente avant notification du group
  group_interval: 1m		# délai par rapport aux alertes du même groupe
  repeat_interval: 30s		# attente avant répétition
  receiver: 'email-me'
#  routes:
#  - match:
#      alertname: Trop_2_load

receivers:
  - name: 'null'
  - name: 'email-me'
    email_configs:
    - to: 'xxx@moi.fr'
      from: 'yyy@moi.fr'
      smarthost: '127.0.0.1:2525'
#      headers:
#        subject: '{{ template \"custom_mail_subject\" . }}'
#      html: '{{ template \"custom_mail_html\" . }}'
#
#templates:
#- '/etc/alertmanager/templates/*.tmpl'

" > /etc/alertmanager/alertmanager.yml

chown alertmanager:alertmanager /etc/alertmanager/alertmanager.yml

}

alertmanager_systemd_service(){

echo "
[Unit]
Description=Alertmanager
Wants=network-online.target
After=network-online.target

[Service]
User=alertmanager
Group=alertmanager
Type=simple
WorkingDirectory=/etc/alertmanager/
ExecStart=/usr/local/bin/alertmanager \
      --storage.path=/var/lib/alertmanager/ \
      --config.file=/etc/alertmanager/alertmanager.yml \
      --cluster.peer=${ALERTMANAGER_PEER}:9094 \
      --web.external-url http://0.0.0.0:9093

[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/alertmanager.service

}

alertmanager_start_enable_service(){

systemctl start alertmanager
systemctl enable alertmanager

}

## Fake smtp

install_fake_smtp(){

docker run -p 8080:80 -p 2525:25 -d --name smtpdev rnwood/smtp4dev

}

## Karma

install_karma(){

docker run -d --name karma -p 8081:8080 -e ALERTMANAGER_URI=http://172.17.0.1:9093 ghcr.io/prymitive/karma:latest

}

# Let's Go !! #################################################

if [ ! -f "/usr/local/bin/vmalert-prod" ]; then
  victoria_alert_install
fi

victoria_alert_dir
victoria_alert_systemd_service
victoria_alert_rules
victoria_alert_restart



alertmanager_create_user_dir
alertmanager_install_binary
alertmanager_configuration_file
alertmanager_systemd_service
alertmanager_start_enable_service
install_karma
install_fake_smtp