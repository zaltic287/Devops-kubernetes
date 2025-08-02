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

ZOO_ID=$(hostname | sed "s/zoo//g")

if [[ ${ZOO_ID} == "1" ]];then ZOO1="server.1=0.0.0.0:2888:3888"; else ZOO1="server.1=zoo1:2888:3888";fi
if [[ ${ZOO_ID} == "2" ]];then ZOO2="server.2=0.0.0.0:2888:3888"; else ZOO2="server.2=zoo2:2888:3888";fi
if [[ ${ZOO_ID} == "3" ]];then ZOO3="server.3=0.0.0.0:2888:3888"; else ZOO3="server.3=zoo3:2888:3888";fi
if [[ ${ZOO_ID} == "4" ]];then ZOO4="server.4=0.0.0.0:2888:3888"; else ZOO4="server.4=zoo4:2888:3888";fi
if [[ ${ZOO_ID} == "5" ]];then ZOO5="server.5=0.0.0.0:2888:3888"; else ZOO5="server.5=zoo5:2888:3888";fi
if [[ ${ZOO_ID} == "6" ]];then ZOO6="server.6=0.0.0.0:2888:3888"; else ZOO6="server.6=zoo6:2888:3888";fi

# Functions ###################################################

install_zookeeper(){

apt update && apt install -y -qq zookeeper netcat

}

config_zookeeper(){

echo "
autopurge.purgeInterval=1
autopurge.snapRetainCount=5
# To avoid seeks ZooKeeper allocates space in the transaction log file in blocks of preAllocSize kilobytes.
# The default block size is 64M. One reason for changing the size of the blocks is to reduce the block size
# if snapshots are taken more often. (Also, see snapCount).
preAllocSize=65536
# ZooKeeper logs transactions to a transaction log. After snapCount transactions are written to a log file a
# snapshot is started and a new transaction log file is started. The default snapCount is 10,000.
snapCount=10000
# define servers ip and internal ports to zookeeper
${ZOO1}
${ZOO2}
${ZOO3}
${ZOO4}
${ZOO5}
${ZOO6}
" >> /etc/zookeeper/conf/zoo.cfg

echo ${ZOO_ID} > /etc/zookeeper/conf/myid

}

systemd_zookeeper(){

echo "Create a service systemd for Zookeeper"
echo '[Unit]
Description=Apache Zookeeper Server
Documentation=http://kafka.apache.org/documentation.html
Requires=network.target
After=network.target zookeeper.service

[Service]
Type=forking
User=zookeeper
Group=zookeeper

ExecStart=/usr/share/zookeeper/bin/zkServer.sh start /etc/zookeeper/conf/zoo.cfg
ExecStop=/usr/share/zookeeper/bin/zkServer.sh stop /etc/zookeeper/conf/zoo.cfg
ExecReload=/usr/share/zookeeper/bin/zkServer.sh restart /etc/zookeeper/conf/zoo.cfg
Restart=on-abnormal

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/zookeeper.service

}


start_zookeeper(){

echo "Restart & enable zookeeper"

systemctl enable zookeeper
#systemctl start zookeeper

}

## Run #########################################################

install_zookeeper
config_zookeeper
systemd_zookeeper
start_zookeeper

