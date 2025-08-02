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
USER_APP=victoriametrics

if [[ "$1" == "y" ]];then 
  INSERTER_DNS="127.0.0.1:8427"
  cluster=1
else
  INSERTER_DNS="vic1:8428"
  cluster=0
fi

if [[ "$2" == "y" ]];then 
  node_exporter=1
else
  node_exporter=0
fi

# Functions ###################################################

victoria_install(){

wget -qq https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v${VERSION}/vmutils-linux-amd64-v${VERSION}.tar.gz
tar xzf vmutils-linux-amd64-v${VERSION}.tar.gz -C /usr/local/bin/
chmod -R +x /usr/local/bin/

groupadd --system ${USER_APP}
useradd -s /sbin/nologin --system -g ${USER_APP} ${USER_APP}

mkdir -p mkdir -p /etc/vmagent/ /var/lib/vmagent/ /etc/vmauth/
chown -R ${USER_APP}:${USER_APP} /etc/vmagent/ /var/lib/vmagent/ /etc/vmauth/

}

victoria_agent_systemd_service(){
echo "
[Unit]
Description=Description=VMAgent service
After=network.target

[Service]
Type=simple
User=${USER_APP}
ExecStart=/usr/local/bin/vmagent-prod \
      -promscrape.config=/etc/vmagent/config.yml \
      -remoteWrite.url=http://${INSERTER_DNS}/api/v1/write \
      -promscrape.config.strictParse=false \
      -remoteWrite.tmpDataPath=/var/lib/vmagent/

SyslogIdentifier=vmagent
Restart=always

[Install]
WantedBy=multi-user.target
" >/etc/systemd/system/vmagent.service
}


victoria_auth_systemd_service(){
echo "
[Unit]
Description=Description=VMAuth service
After=network.target

[Service]
Type=simple
User=${USER_APP}
ExecStart=/usr/local/bin/vmauth-prod \
      -configCheckInterval=5s \
      -auth.config=/etc/vmauth/config.yml

SyslogIdentifier=vmauth
Restart=always

[Install]
WantedBy=multi-user.target
" >/etc/systemd/system/vmauth.service
}

victoria_agent_configuration(){

echo "
global:
  scrape_interval:     5s 
  evaluation_interval: 5s 
  external_labels:
    datacenter: 'dc1'
scrape_configs:
" > /etc/vmagent/config.yml

if [[ "${cluster}" == "1" ]];then 
echo "
  - job_name: job_vminsert
    static_configs:
      - targets: 
        - vic1:8480
        - vic2:8480
        - vic3:8480
  - job_name: job_vmselect
    static_configs:
      - targets: 
        - vic1:8481
        - vic2:8481
        - vic3:8481
  - job_name: job_vmstorage
    static_configs:
      - targets: 
        - vic1:8482
        - vic2:8482
        - vic3:8482
" >> /etc/vmagent/config.yml
fi

if [[ "${node_exporter}" == "1" ]];then
echo "
  - job_name: node_exporter
    static_configs:
      - targets: 
" >> /etc/vmagent/config.yml

awk '$1 ~ "^192.168" {print "        - "$2":9100"}' /etc/hosts >> /etc/vmagent/config.yml

fi
}

victoria_auth_configuration(){
echo '
unauthorized_user:
  url_map:
  - src_paths:
    - /targets
    - /static.+
    - /service-discovery
    - /target-relabel-debug
    url_prefix:
    - http://vmagent1:8429
    - http://vmagent2:8429
  - src_paths:
    - /api/v1/write
    url_prefix:
    - http://vic1:8480/insert/1/prometheus
    - http://vic2:8480/insert/1/prometheus
    - http://vic3:8480/insert/1/prometheus
  - src_paths:
    - /api/v1/series
    - /api/v1/query
    - /api/v1/query_range
    - /api/v1/label/[^/]+/values
    url_prefix:
    - http://vic1:8481/select/1/prometheus
    - http://vic2:8481/select/1/prometheus
    - http://vic3:8481/select/1/prometheus
  - src_paths:
    - "/vmui.+"
    - "/prometheus.+"
    url_prefix:
    - http://vic1:8481/select/1
    - http://vic2:8481/select/1
    - http://vic3:8481/select/1
  - src_paths:
    - "/alertmanager.*"
    drop_src_path_prefix_parts: 1
    url_prefix:
    - http://vmagent1:9093/
    - http://vmagent2:9093/
' > /etc/vmauth/config.yml

}

victoria_agent_restart(){
  systemctl restart vmagent
  systemctl enable vmagent
}

victoria_auth_restart(){
  systemctl restart vmauth
  systemctl enable vmauth
}

# Let's Go !! #################################################


victoria_install

victoria_agent_systemd_service
victoria_agent_configuration
victoria_agent_restart

if [[ "$1" == "y" ]];then 
victoria_auth_systemd_service
victoria_auth_configuration
victoria_auth_restart
fi
