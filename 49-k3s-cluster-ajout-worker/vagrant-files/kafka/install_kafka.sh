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

KRAFT=$1
SCALA_VERSION="2.13"
KAFKA_VERSION="3.7.0"
VERSION=${SCALA_VERSION}-${KAFKA_VERSION}
BROKER_ID=$(hostname | sed "s/kafka//g")

if [[ ${BROKER_ID} == "1" ]];then BROKER1="server.1=0.0.0.0:2888:3888";KRAFT1="1@localhost:9093"; else BROKER1="server.1=kafka1:2888:3888";KRAFT1="1@kafka1:9093" ;fi
if [[ ${BROKER_ID} == "2" ]];then BROKER2="server.2=0.0.0.0:2888:3888";KRAFT2="2@localhost:9093"; else BROKER2="server.2=kafka2:2888:3888";KRAFT2="2@kafka2:9093" ;fi
if [[ ${BROKER_ID} == "3" ]];then BROKER3="server.3=0.0.0.0:2888:3888";KRAFT3="3@localhost:9093"; else BROKER3="server.3=kafka3:2888:3888";KRAFT3="3@kafka3:9093" ;fi

# Functions ###################################################


install_kafka(){

echo "Kafka installation..."

swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

groupadd --system kafka
useradd -s /sbin/nologin --system -g kafka kafka

wget -q https://downloads.apache.org/kafka/${KAFKA_VERSION}/kafka_${VERSION}.tgz

tar xzf kafka_${VERSION}.tgz
mv kafka_${VERSION} /opt/kafka
chown -R kafka:kafka /opt/kafka

mkdir -p /data/kafka
chown -R kafka:kafka /data/

}

install_zookeeper_systemd(){

echo "Create a service systemd for Zookeeper"
echo '[Unit]
Description=Apache Zookeeper Server
Documentation=http://kafka.apache.org/documentation.html
Requires=network.target
After=network.target zookeeper.service

[Service]
Type=simple
User=kafka
Group=kafka

Environment=JAVA_OPTS="-Djava.net.preferIPv4Stack=true"
Environment=JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64/
ExecStart=/opt/kafka/bin/zookeeper-server-start.sh /opt/kafka/config/zookeeper.properties
ExecStop=/opt/kafka/bin/zookeeper-server-stop.sh
Restart=on-abnormal

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/zookeeper.service

}

config_zookeeper(){

mkdir -p /data/zookeeper
chown -R kafka:kafka /data/

echo "
# the directory where the snapshot is stored.
dataDir=/data/zookeeper
# the port at which the clients will connect
clientPort=2181
# setting number of connections to unlimited
maxClientCnxns=0
# keeps a heartbeat of zookeeper in milliseconds
tickTime=2000
# time for initial synchronization
initLimit=10
# how many ticks can pass before timeout
syncLimit=5
# whitelist command
4lw.commands.whitelist=*
# define servers ip and internal ports to zookeeper
${BROKER1}
${BROKER2}
${BROKER3}
${BROKER4}" > /opt/kafka/config/zookeeper.properties

echo ${BROKER_ID} > /data/zookeeper/myid

}

config_kafka(){

echo '
# change this for each broker
broker.id='${BROKER_ID}'
# change this to the hostname of each broker
advertised.listeners=PLAINTEXT://'$(hostname)':9092
# The ability to delete topics
delete.topic.enable=true
# Where logs are stored
log.dirs=/data/kafka
# default number of partitions
num.partitions=8
# default replica count based on the number of brokers
default.replication.factor=3
# to protect yourself against broker failure
min.insync.replicas=2
# logs will be deleted after how many hours
log.retention.hours=168
# size of the log files 
log.segment.bytes=1073741824
# check to see if any data needs to be deleted
log.retention.check.interval.ms=300000
# location of all zookeeper instances and kafka directory
zookeeper.connect=kafka1:2181,kafka2:2181,kafka3:2181/kafka
# timeout for connecting with zookeeper
zookeeper.connection.timeout.ms=6000
# automatically create topics
auto.create.topics.enable=true
' > /opt/kafka/config/server.properties

}

install_kafka_systemd(){

if [[ "$KRAFT" == "yes" ]]; then
KRAFT_DIR="kraft/"
fi

echo "Create a service systemd for Kafka"
echo '[Unit]
Description=Apache Kafka Server
Documentation=http://kafka.apache.org/documentation.html
Requires=network.target
After=network.target zookeeper.service

[Service]
Type=simple
User=kafka
Group=kafka

Environment=JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64/
ExecStart=/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/'${KRAFT_DIR}'server.properties
ExecStop=/opt/kafka/bin/kafka-server-stop.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/kafka.service

}

config_kraft(){

echo '
process.roles=broker,controller
node.id='${BROKER_ID}'
controller.quorum.voters='${KRAFT1}','${KRAFT2}','${KRAFT3}'
listeners=PLAINTEXT://:9092,CONTROLLER://:9093
inter.broker.listener.name=PLAINTEXT
advertised.listeners=PLAINTEXT://'$(hostname)':9092
controller.listener.names=CONTROLLER
listener.security.protocol.map=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT,SSL:SSL,SASL_PLAINTEXT:SASL_PLAINTEXT,SASL_SSL:SASL_SSL
num.network.threads=3
num.io.threads=8
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
log.dirs=/data/kafka
num.partitions=1
num.recovery.threads.per.data.dir=1
offsets.topic.replication.factor=1
transaction.state.log.replication.factor=1
transaction.state.log.min.isr=1
log.retention.hours=168
log.segment.bytes=1073741824
log.retention.check.interval.ms=300000
' > /opt/kafka/config/kraft/server.properties
}

start_zookeeper(){

echo "Start & enable zookeeper"
systemctl enable zookeeper
systemctl start zookeeper

}

start_kafka(){

echo "Start & enable kafka"
/opt/kafka/bin/kafka-storage.sh format -t HacYvBUxTUae3mEHNHqurA -c /opt/kafka/config/kraft/server.properties
systemctl enable kafka
systemctl start kafka

}


# Let's Go !! #################################################

if [[ "$KRAFT" == "yes" ]]; then

install_kafka
config_kraft
install_kafka_systemd
start_kafka

else

install_kafka
config_zookeeper
config_kafka
install_zookeeper_systemd
install_kafka_systemd
start_zookeeper
start_kafka

fi
