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
# 		https://github.com/apache/pulsar
###############################################################



# Variables ###################################################

PULSAR_VERSION=3.0.0
PULSAR_ID=$(hostname | sed "s/pulsar//g")

MODE=$1

if [[ $1 == "external-pulsar" ]];then
  PULSAR_ID=$(hostname | sed "s/ext-pulsar//g")
fi

# Functions ###################################################



# Let's Go !! #################################################


configuration_pulsar(){

sed -i s/"journalDirectory=.*"/"journalDirectory=\/data\/bookeeper\/journal"/g /opt/pulsar/conf/bookkeeper.conf
sed -i s/"advertisedAddress=.*"/"advertisedAddress=${HOSTNAME}"/g /opt/pulsar/conf/bookkeeper.conf
sed -i s/"ledgerDirectories=.*"/"ledgerDirectories=\/data\/bookeeper\/ledgers"/g /opt/pulsar/conf/bookkeeper.conf
if [[ "$MODE" == "external-pulsar" ]];then
  sed -i s/"zkServers=.*"/"zkServers=ext-pulsar1:2181"/g /opt/pulsar/conf/bookkeeper.conf
else
  sed -i s/"zkServers=.*"/"zkServers=pulsar1:2181,pulsar2:2181,pulsar3:2181"/g /opt/pulsar/conf/bookkeeper.conf
fi
sed -i s/"prometheusStatsHttpPort=.*"/"prometheusStatsHttpPort=8889"/g /opt/pulsar/conf/bookkeeper.conf


if [[ "$MODE" == "external-pulsar" ]];then
  sed -i s/"zookeeperServers=.*"/"zookeeperServers=ext-pulsar1:2181"/g /opt/pulsar/conf/broker.conf
else
  sed -i s/"zookeeperServers=.*"/"zookeeperServers=pulsar1:2181,pulsar2:2181,pulsar3:2181"/g /opt/pulsar/conf/broker.conf
fi
if [[ "$MODE" == "georeplication" ]] || [[ "$MODE" == "external-pulsar" ]];then
  sed -i s/"configurationStoreServers=.*"/"configurationStoreServers=ext-zook1:2181"/g /opt/pulsar/conf/broker.conf
else
  sed -i s/"configurationStoreServers=.*"/"configurationStoreServers=pulsar1:2181,pulsar2:2181,pulsar3:2181"/g /opt/pulsar/conf/broker.conf
fi
sed -i s/"advertisedAddress=.*"/"advertisedAddress=${HOSTNAME}"/g /opt/pulsar/conf/broker.conf
if [[ "$MODE" == "external-pulsar" ]];then
  sed -i s/"clusterName=.*"/"clusterName=Saliou-geo"/g /opt/pulsar/conf/broker.conf
else
  sed -i s/"clusterName=.*"/"clusterName=Saliou"/g /opt/pulsar/conf/broker.conf
fi
sed -i s/"webServicePort=.*"/"webServicePort=8082"/g /opt/pulsar/conf/broker.conf
sed -i s/"exposeTopicLevelMetricsInPrometheus=.*"/"exposeTopicLevelMetricsInPrometheus=true"/g /opt/pulsar/conf/broker.conf
sed -i s/"exposeConsumerLevelMetricsInPrometheus=.*"/"exposeConsumerLevelMetricsInPrometheus=true"/g /opt/pulsar/conf/broker.conf
sed -i s/"exposeProducerLevelMetricsInPrometheus=.*"/"exposeProducerLevelMetricsInPrometheus=true"/g /opt/pulsar/conf/broker.conf
echo "bookkeeperClientExposeStatsToPrometheus=true">> /opt/pulsar/conf/broker.conf

}

systemd_pulsar(){

echo '
[Unit]
Description=BookKeeper
After=network.target

[Service]
User=pulsar
Group=pulsar
Environment=PULSAR_MEM="-Xms512m -Xmx512m -XX:MaxDirectMemorySize=1g"
ExecStart=/opt/pulsar/bin/pulsar bookie
WorkingDirectory=/opt/pulsar
RestartSec=5s
Restart=on-failure
Type=simple

[Install]
WantedBy=multi-user.target
' > /etc/systemd/system/pulsar-bookeeper.service

echo '
[Unit]
Description=Pulsar Broker
After=network.target

[Service]
User=pulsar
Group=pulsar
Environment=PULSAR_MEM="-Xms512m -Xmx512m -XX:MaxDirectMemorySize=1g"
ExecStart=/opt/pulsar/bin/pulsar broker
WorkingDirectory=/opt/pulsar
RestartSec=5s
Restart=on-failure
Type=simple

[Install]
WantedBy=multi-user.target
' > /etc/systemd/system/pulsar-broker.service

echo '
[Unit]
Description=Pulsar Proxy
After=network.target

[Service]
User=pulsar
Group=pulsar
ExecStart=/opt/pulsar/bin/pulsar proxy
WorkingDirectory=/opt/pulsar
RestartSec=5s
Restart=on-failure
Type=simple

[Install]
WantedBy=multi-user.target
' > /etc/systemd/system/pulsar-proxy.service

systemctl start pulsar-bookeeper
systemctl enable pulsar-bookeeper
systemctl start pulsar-broker
systemctl enable pulsar-broker

}

# Let's Go !! #################################################

configuration_pulsar
systemd_pulsar

if [[ $PULSAR_ID == "3" ]] || [[ "${MODE}" == "external-pulsar" ]];then
  sleep 20s
  if [[ ${MODE} == "external-pulsar" ]];then
    PULSAR_MEM="-Xms512m -Xmx512m -XX:MaxDirectMemorySize=1g" /vagrant/initialize.sh georeplication
    sleep 15s
    /opt/pulsar/bin/pulsar-admin --admin-url http://127.0.0.1:8082 tenants create geotenant
    /opt/pulsar/bin/pulsar-admin --admin-url http://127.0.0.1:8082 namespaces create geotenant/geons
    /opt/pulsar/bin/pulsar-admin --admin-url http://127.0.0.1:8082 topics create-partitioned-topic geotenant/geons/Saliou-topic-geo -p 6
  else
    PULSAR_MEM="-Xms512m -Xmx512m -XX:MaxDirectMemorySize=1g" /vagrant/initialize.sh
    sleep 15s
    /opt/pulsar/bin/pulsar-admin --admin-url http://127.0.0.1:8082 tenants create xtenant
    /opt/pulsar/bin/pulsar-admin --admin-url http://127.0.0.1:8082 namespaces create xtenant/xns
    /opt/pulsar/bin/pulsar-admin --admin-url http://127.0.0.1:8082 topics create-partitioned-topic xtenant/xns/Saliou-topic -p 6
  fi
  sleep 15s
fi
