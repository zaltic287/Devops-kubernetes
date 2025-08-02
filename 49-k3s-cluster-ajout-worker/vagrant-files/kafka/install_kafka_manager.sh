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

# Functions ###################################################


install_kafka_manager() {

echo "Kafka Manager installation..."

groupadd --system kafka
useradd -s /sbin/nologin --system -g kafka kafka

apt install unzip

wget -q https://github.com/yahoo/CMAK/releases/download/3.0.0.6/cmak-3.0.0.6.zip

unzip -qq cmak-3.0.0.6.zip
mv  cmak-3.0.0.6 /opt/kafka_manager
chown -R kafka:kafka /opt/kafka_manager


echo '[Unit]
Description=Apache Kafka Manager
Documentation=http://kafka.apache.org/documentation.html
Requires=network.target
After=network.target 

[Service]
Type=simple
User=kafka
Group=kafka

Environment=ZK_HOSTS="kafka1:2181,kafka2:2181,kafka3:2181"
ExecStart=/opt/kafka_manager/bin/cmak
Restart=on-failure

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/kafka_manager.service

systemctl daemon-reload
systemctl start kafka_manager
systemctl enable kafka_manager

}

install_benthos(){
  curl -Lsf https://sh.benthos.dev | bash 2>&1 >/dev/null
}

install_akhq(){
echo '
micronaut:
  security:
    enabled: true
akhq:
  security:
    default-group: no-roles
    basic-auth:
      - username: admin
        password: "5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8"
        groups:
        - admin
  connections:
    kafka-Saliou:
      properties:
        bootstrap.servers: "kafka1:9092;kafka2:9092;kafka3:9092"
'>/var/lib/application.yml
  curl -fsSL https://get.docker.com -o get-docker.sh 2>&1 >/dev/null
  sudo sh get-docker.sh 2>&1 >/dev/null
  sudo usermod -aG docker vagrant
  sudo service docker start
	docker run -d -p 8080:8080 --name akhq -v /var/lib/application.yml:/app/application.yml --add-host kafka1:192.168.12.78 --add-host kafka2:192.168.12.79 --add-host kafka3:192.168.12.80 tchiotludo/akhq
}

install_kafkactl(){

wget https://github.com/deviceinsight/kafkactl/releases/download/v3.1.0/kafkactl_3.1.0_linux_amd64.deb

dpkg -i kafkactl_3.1.0_linux_amd64.deb
mkdir -p /home/vagrant/.config/kafkactl/
echo '
contexts:
  Saliou-cluster:
    brokers:
    - kafka1:9092
    - kafka2:9092
    - kafka3:9092

    tls:
      enabled: false
      insecure: false

    sasl:
      enabled: false

current-context: Saliou-cluster
'> /home/vagrant/.config/kafkactl/config.yml

chown -R vagrant:vagrant /home/vagrant/.config/kafkactl/

}

benthos_sample_config(){

echo '
http:
  address: 0.0.0.0:4196
#https://www.benthos.dev/docs/components/inputs/generate

input:
  generate:
    count: 1000000
    interval: ""
    mapping: |
      root.received_at = now()
      root.message = "Je suis un message " + random_int().string()
      root.id = uuid_v4()
      root.host = hostname()
#https://www.benthos.dev/docs/components/outputs/file

output:
  kafka_franz:
    seed_brokers:
      - kafka1:9092
      - kafka2:9092
      - kafka3:9092
    topic: Saliou
' > sample_kafka_producer.yml

}

# Let's Go !! #################################################

if [[ "$KRAFT" == "yes" ]];then
install_akhq
else
install_kafka_manager
fi

install_benthos
benthos_sample_config
