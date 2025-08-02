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

cp /vagrant/rules-scylla.yml /etc/prometheus/scylla-rules.yml

echo "
global:
  scrape_interval:     10s 
  evaluation_interval: 10s 
  external_labels:
    youtube: 'Saliou'
rule_files:
  - /etc/prometheus/scylla-rules.yml
scrape_configs:
  - job_name: node_exporter
    static_configs:
      - targets: 
" > /etc/prometheus/prometheus.yml
awk '$1 ~ "^192.168" {print "        - "$2":9100"}' /etc/hosts >> /etc/prometheus/prometheus.yml
echo "
  - job_name: scylla_metrics
    static_configs:
      - targets:" >> /etc/prometheus/prometheus.yml
awk '$1 ~ "^192.168" && $2 ~ "scylla" {print "        - "$2":9180"}' /etc/hosts >> /etc/prometheus/prometheus.yml
echo "
        labels:
          cluster: 'Saliou'
    metric_relabel_configs:
        - source_labels: [__name__]
          regex: \"(scylla_cache_row_insertions|scylla_io_queue_total_read_bytes|scylla_io_queue_total_write_bytes|scylla_io_queue_total_read_ops|scylla_io_queue_total_bytes|scylla_database_active_reads_memory_consumption|scylla_cache_row_insertions|scylla_cache_row_misses|scylla_cache_row_hits|scylla_cache_partition_removals|scylla_cache_partition_insertions|scylla_cache_dummy_row_hits|scylla_cache_row_evictions|scylla_cache_bytes_used|scylla_cache_bytes_total|scylla_sstables_bloom_filter_memory_size|scylla_cache_partition_evictions|scylla_scylladb_current_version|scylla_cache_bytes_total|scylla_storage_proxy_coordinator_write_latency_count|scylla_storage_proxy_coordinator_read_latency_count|scylla_transport_requests_served|scylla_transport_current_connections|scylla_compaction_manager_compactions|scylla_storage_proxy_coordinator_read_timeouts|scylla_storage_proxy_coordinator_cas_read_timeouts|scylla_storage_proxy_coordinator_range_timeouts|scylla_storage_proxy_coordinator_write_timeouts|scylla_cache_row_hits|scylla_cache_row_misses|scylla_manager_task_run_total|scylla_manager_task_active_count|scylla_manager_repair_token_ranges_total|scylla_manager_repair_token_ranges_success|scylla_manager_repair_token_ranges_error|scylla_manager_backup_files_size_bytes|scylla_manager_backup_files_uploaded_bytes|scylla_manager_backup_files_skipped_bytes|scylla_manager_backup_files_failed_bytes|scylla_storage_proxy_coordinator_write_latency_bucket|scylla_storage_proxy_coordinator_read_latency_bucket)\"
          action: keep
" >> /etc/prometheus/prometheus.yml
}

prometheus_restart(){
  systemctl restart prometheus
  systemctl enable prometheus
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

cp /vagrant/scylla-dashboard.json /var/lib/grafana/

echo "
apiVersion: 1
providers:
- name: 'scylla'
  orgId: 1
  folder: ''
  type: file
  disableDeletion: false
  updateIntervalSeconds: 10 
  options:
    path: /var/lib/grafana/scylla-dashboard.json
" > /etc/grafana/provisioning/dashboards/dashboard-scylla.yml

chown -R root:grafana /etc/grafana/provisioning/dashboards/*

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
systemctl start grafana-server
systemctl enable grafana-server
}

# Let's Go !! #################################################

prometheus_install
prometheus_configuration
prometheus_restart
grafana_install
grafana_edit_configuration
grafana_dashboard
grafana_restart
