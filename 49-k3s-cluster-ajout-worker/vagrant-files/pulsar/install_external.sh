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



# Functions ###################################################


add_sample_config(){
echo "
input:
  generate:
    count: 100000000
    interval: '2s'
    mapping: |
      root.message = \"Message: \" + random_int().string()

output:
  pulsar:
    url: \"pulsar://pulsar1:6650\"
    topic: \"xtenant/xns/Saliou-topic\"
    max_in_flight: 64
" > /home/vagrant/producer_sample.yml

echo "
http:
  address: 0.0.0.0:4196
input:
  pulsar:
    url: pulsar://pulsar1:6650
    topics: 
      - \"xtenant/xns/Saliou-topic\"
    subscription_name: "subx"

output:
  stdout:
    codec: lines

" > /home/vagrant/consumer_sample.yml
}

install_benthos(){
  curl -Lsf https://sh.benthos.dev | bash 2>&1 >/dev/null
}

install_docker(){
curl -fsSL https://get.docker.com -o get-docker.sh 2>&1 >/dev/null
chmod +x get-docker.sh
./get-docker.sh 2>&1 >/dev/null
usermod -aG docker vagrant
curl -fsSL "https://github.com/docker/compose/releases/download/1.25.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose 2>&1 >/dev/null
chmod +x /usr/local/bin/docker-compose
}

launch_pulsar_manager(){
docker-compose -f /vagrant/docker-compose.yml up -d
}

install_pulsar_manager(){

wget https://raw.githubusercontent.com/apache/pulsar-manager/master/src/main/resources/META-INF/sql/postgresql-schema.sql

wget https://raw.githubusercontent.com/apache/pulsar-manager/master/src/main/resources/application.properties

sed -i s/spring.datasource.driver-class-name=.*/spring.datasource.driver-class-name=org.postgresql.Driver/g application.properties

sed -i s/spring.datasource.url=.*/"spring.datasource.url=jdbc:postgresql:\/\/postgresql:5432\/pulsar_manager"/g application.properties

sed -i s/spring.datasource.username=.*/spring.datasource.username=Saliou/g application.properties

sed -i s/spring.datasource.password=.*/spring.datasource.password=password/g application.properties

sed -i s/spring.datasource.initialization-mode=.*/#spring.datasource.initialization-mode=always/g application.properties

}

init_pulsar_manager(){

CSRF_TOKEN=$(curl http://127.0.0.1:7750/pulsar-manager/csrf-token)
curl    -H 'X-XSRF-TOKEN: $CSRF_TOKEN'    -H 'Cookie: XSRF-TOKEN=$CSRF_TOKEN;'    -H "Content-Type: application/json"    -X PUT http://127.0.0.1:7750/pulsar-manager/users/superuser    -d '{"name": "Saliou", "password": "password", "description": "test", "email": "username@test.org"}'
}

## add http://192.168.13.170:8082 and http://192.168.13.170:8000

# Let's Go !! #################################################

add_sample_config
install_benthos
install_docker
install_pulsar_manager
launch_pulsar_manager
sleep 30s
init_pulsar_manager
