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



# Variables ###################################################

ZOO_ID=$(hostname | sed "s/pulsar//g")

if [[ $1 == "external_zookeeper" ]];then
  ZOO1="server.11=0.0.0.0:2888:3888";
  ZOO_ID="11"
elif [[ $1 == "external-pulsar" ]];then
  ZOO1="server.12=0.0.0.0:2888:3888";
  ZOO_ID="12"
else
  if [[ ${ZOO_ID} == "1" ]] ;then ZOO1="server.1=0.0.0.0:2888:3888"; else ZOO1="server.1=pulsar1:2888:3888";fi
  if [[ ${ZOO_ID} == "2" ]] ;then ZOO2="server.2=0.0.0.0:2888:3888"; else ZOO2="server.2=pulsar2:2888:3888";fi
  if [[ ${ZOO_ID} == "3" ]] ;then ZOO3="server.3=0.0.0.0:2888:3888"; else ZOO3="server.3=pulsar3:2888:3888";fi
fi


# Functions ###################################################


config_zookeeper(){

sed -i s/"dataDir=.*"/"dataDir=\/data\/zookeeper"/g /opt/pulsar/conf/zookeeper.conf
sed -i s/"admin.serverPort=.*"/"admin.serverPort=8090"/g /opt/pulsar/conf/zookeeper.conf
sed -i s/"metricsProvider.httpPort=.*"/"metricsProvider.httpPort=8888"/g /opt/pulsar/conf/zookeeper.conf

echo "

# define servers ip and internal ports to zookeeper
${ZOO1}
${ZOO2}
${ZOO3}

" >> /opt/pulsar/conf/zookeeper.conf

echo ${ZOO_ID} > /data/zookeeper/myid

}

systemd_zookeeper(){

echo "Create a service systemd for Zookeeper"
echo '[Unit]
Description=Apache Zookeeper Server
Documentation=http://kafka.apache.org/documentation.html
Requires=network.target
After=network.target

[Service]
User=pulsar
Group=pulsar
Environment=PULSAR_MEM="-Xms512m -Xmx512m -XX:MaxDirectMemorySize=1g"
ExecStart=/opt/pulsar/bin/pulsar zookeeper
WorkingDirectory=/opt/pulsar
RestartSec=5s
Restart=on-failure
Type=simple

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/pulsar-zookeeper.service

}


start_zookeeper(){

echo "Restart & enable zookeeper"

systemctl enable pulsar-zookeeper
systemctl start pulsar-zookeeper

}

## Run #########################################################

config_zookeeper
systemd_zookeeper
start_zookeeper

