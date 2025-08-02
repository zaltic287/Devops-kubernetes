#!/bin/bash

# Variables ###################################################

#ETCD_VERSION="v3.5.0"
ETCD_VERSION="v3.3.27"
ETCD_USER="etcd"
ETCD_GROUP="etcd"
ETCD_BIN_DIR="/usr/local/bin"
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_CONFIG_FILE="/etc/default/etcd"
ETCD_SERVICE_FILE="/etc/systemd/system/etcd.service"

HOST_IP=$(hostname -I | awk '{print $2}')  # Use the primary IP address
ETCD1_IP=$(awk '$2 == "etcd1" && $1 != "127.0.1.1" {print $1}' /etc/hosts)
ETCD2_IP=$(awk '$2 == "etcd2" && $1 != "127.0.1.1" {print $1}' /etc/hosts)
ETCD3_IP=$(awk '$2 == "etcd3" && $1 != "127.0.1.1" {print $1}' /etc/hosts)

CLUSTER="etcd1=http://$ETCD1_IP:2380,etcd2=http://$ETCD2_IP:2380,etcd3=http://$ETCD3_IP:2380"

if [ "$(hostname)" == "etcd1" ]; then
  CLUSTER_STATE="new"
else
  CLUSTER_STATE="new"
fi

sed -i /'^127.0.1.1.*'/d /etc/hosts

# Functions ###################################################

install_prerequisites(){
  apt update && apt install -y wget tar
}

install_etcd_user(){
  if ! id -u "$ETCD_USER" >/dev/null 2>&1; then
    groupadd --system etcd
    useradd -s /sbin/nologin --system -g etcd etcd
  fi
}

install_etcd(){
  wget -q https://github.com/etcd-io/etcd/releases/download/${ETCD_VERSION}/etcd-${ETCD_VERSION}-linux-amd64.tar.gz
  tar -xzf "etcd-${ETCD_VERSION}-linux-amd64.tar.gz"
  mv "etcd-${ETCD_VERSION}-linux-amd64/etcd"* "$ETCD_BIN_DIR/"
  chmod +x "${ETCD_BIN_DIR}/etcd" "${ETCD_BIN_DIR}/etcdctl"
  rm -rf "etcd-${ETCD_VERSION}-linux-amd64.tar.gz" "etcd-${ETCD_VERSION}-linux-amd64"
  mkdir -p "$ETCD_DATA_DIR"
  chown -R "$ETCD_USER:$ETCD_GROUP" "$ETCD_DATA_DIR"
  chmod 700 "$ETCD_DATA_DIR"
}

create_configuration(){
echo "ETCD_NAME=\"$(hostname)\"
ETCD_DATA_DIR=\"$ETCD_DATA_DIR\"
ETCD_LISTEN_PEER_URLS=\"http://$HOST_IP:2380\"
ETCD_LISTEN_CLIENT_URLS=\"http://$HOST_IP:2379,http://127.0.0.1:2379\"
ETCD_INITIAL_ADVERTISE_PEER_URLS=\"http://$HOST_IP:2380\"
ETCD_ADVERTISE_CLIENT_URLS=\"http://$HOST_IP:2379\"
ETCD_INITIAL_CLUSTER=\"$CLUSTER\"
ETCD_INITIAL_CLUSTER_TOKEN=\"etcd-cluster\"
ETCD_INITIAL_CLUSTER_STATE="$CLUSTER_STATE > $ETCD_CONFIG_FILE
}

create_systemd_service(){
echo "[Unit]
Description=etcd - highly-available key value store
Documentation=https://github.com/etcd-io/etcd
After=network.target

[Service]
User=root
Type=exec
EnvironmentFile="$ETCD_CONFIG_FILE"
ExecStart="$ETCD_BIN_DIR"/etcd
  --name=\${ETCD_NAME} \\
  --data-dir=\${ETCD_DATA_DIR} \\
  --initial-advertise-peer-urls=http://\${HOST_IP}:2380 \\
  --listen-peer-urls=http://\${HOST_IP}:2380 \\
  --advertise-client-urls=http://\${HOST_IP}:2379 \\
  --listen-client-urls=http://\${HOST_IP}:2379,http://127.0.0.1:2379 \\
  --initial-cluster-token=etcd-cluster-1 \\
  --initial-cluster=\${ETCD_INITIAL_CLUSTER} \\
  --initial-cluster-state=new
Restart=on-failure
LimitNOFILE=40000

[Install]
WantedBy=multi-user.target" > $ETCD_SERVICE_FILE
}

start_all(){
  systemctl daemon-reload
  systemctl enable etcd
  systemctl start etcd
}

# Let's Go !! #################################################

install_prerequisites
install_etcd_user
install_etcd
create_configuration
create_systemd_service
start_all  # Start the etcd service
