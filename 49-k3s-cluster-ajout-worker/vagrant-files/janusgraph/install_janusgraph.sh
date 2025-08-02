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

IP=$(hostname -I | awk '{print $2}')

# Functions ###################################################


install_prerequisites(){

# Swap off
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# Disable THP
sudo /bin/bash -c 'echo never > /sys/kernel/mm/transparent_hugepage/enabled'
sudo sed -i s/"quiet splash"/"transparent_hugepage=never quiet splash"/g /etc/default/grub
sudo update-grub

# Set swappiness to 0
sudo /bin/bash -c 'echo vm.swappiness = 0 > /etc/sysctl.d/99-sysctl.conf'
sudo sysctl -p


}

clean_host(){
sed -i /'^127.0.1.1.*'/d /etc/hosts
}

install_janus(){
apt install -y zip openjdk-11-jre-headless 2>&1 >/dev/null
groupadd --system janus
useradd -s /sbin/nologin --system -g janus janus

wget -q https://github.com/JanusGraph/janusgraph/releases/download/v0.6.2/janusgraph-full-0.6.2.zip 2>&1 >/dev/null

unzip janusgraph-full-0.6.2.zip 2>&1 >/dev/null

mv janusgraph-full-0.6.2 /opt/janusgraph

chown janus -R /opt/janusgraph

}

install_janus_systemd(){

echo "Create a service systemd for janusgraph"
echo '[Unit]
Description=Janusgraph Server
Requires=network.target
After=network.target

[Service]
Type=simple
User=janus
Group=janus

ExecStart=/opt/janusgraph/bin/janusgraph-server.sh console
Restart=on-failure

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/janusgraph.service

systemctl daemon-reload
systemctl enable janusgraph
systemctl start janusgraph

}



install_es_cql(){
apt install -y python3-pip 2>&1 >/dev/null
pip3 install cqlsh 2>&1 >/dev/null
cqlsh janus1 -e "CREATE KEYSPACE IF NOT EXISTS janusgraph WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 2} ;"
curl -XPUT janus1:9200/janusgraph?pretty -H 'Content-Type: application/json' -d'
{
  "settings": {
    "number_of_shards": 3,
    "number_of_replicas": 2
  }
}
'

}

install_configuration(){
cp /opt/janusgraph/conf/janusgraph-cql-es.properties /opt/janusgraph/conf/Saliou.properties

sed -i s/"-Xms.*"/"-Xms2048M"/g /opt/janusgraph/conf/jvm-11.options
sed -i s/"-Xmx.*"/"-Xmx2048M"/g /opt/janusgraph/conf/jvm-11.options
sed -i s/"storage.hostname=.*"/"storage.hostname=janus1"/g /opt/janusgraph/conf/Saliou.properties
#sed -i s/"index.search.backend=.*"/"index.search.backend=janusgraph"/g /opt/janusgraph/conf/Saliou.properties
sed -i s/"index.search.hostname=.*"/"index.search.hostname=janus1"/g /opt/janusgraph/conf/Saliou.properties
echo "graph.replace-instance-if-exists=true" >>/opt/janusgraph/conf/Saliou.properties

sed -i s/"graph: conf\/janusgraph-inmemory.properties"/"graph: \/opt\/janusgraph\/conf\/Saliou.properties"/g /opt/janusgraph/conf/gremlin-server/gremlin-server.yaml

}

install_visualizer(){
cd /opt/janusgraph
git clone https://github.com/bricaud/graphexp.git
}

# Let's Go !! #################################################

install_prerequisites
clean_host
install_es_cql
install_janus
install_configuration
install_janus_systemd
install_visualizer
