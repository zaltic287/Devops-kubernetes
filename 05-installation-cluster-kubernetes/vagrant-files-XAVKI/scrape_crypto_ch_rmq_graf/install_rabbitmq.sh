#!/bin/bash

## install rabbitmq

RMQ_VERSION="3.9.13"

IP=$(hostname -I | awk '{print $2}')
echo "START - install rabbitmq "$IP


echo "[1]: install erlang-nox & utils"
apt-get update -qq >/dev/null
apt-get install -qq -y erlang-nox >/dev/null


echo "[2]: install rabbitmq"
wget -q https://github.com/rabbitmq/rabbitmq-server/releases/download/v${RMQ_VERSION}/rabbitmq-server_${RMQ_VERSION}-1_all.deb
dpkg -i rabbitmq-server_${RMQ_VERSION}-1_all.deb


echo "[3]: minimal configuration"
rabbitmq-plugins enable rabbitmq_management
echo "YOATBIGKDHUSBLUSTOAW" | sudo tee /var/lib/rabbitmq/.erlang.cookie
echo "listeners.tcp.1 = 0.0.0.0:5672" | sudo tee -a /etc/rabbitmq/rabbitmq.conf
echo "management.tcp.port = 15672" | sudo tee -a /etc/rabbitmq/rabbitmq.conf
systemctl restart rabbitmq-server

echo "[4]: define default user"
rabbitmqctl add_user Saliou password
rabbitmqctl set_permissions -p / Saliou ".*" ".*" ".*"
rabbitmqctl set_user_tags Saliou administrator
rabbitmqctl delete_user guest

echo "[5]: add rabbitmqadmin"
wget https://raw.githubusercontent.com/rabbitmq/rabbitmq-management/master/bin/rabbitmqadmin
mv rabbitmqadmin /usr/local/bin/
chmod +x /usr/local/bin/rabbitmqadmin

echo "[6]: add queues and exchanges"
rabbitmqadmin -u Saliou -p password declare queue --vhost / name=cryptos.target durable=true arguments='{"x-queue-type": "classic"}'
rabbitmqadmin -u Saliou -p password --vhost / declare exchange name=cryptos.target type=direct
rabbitmqadmin -u Saliou -p password --vhost / declare binding source="cryptos.target" destination_type="queue" destination="cryptos.target" routing_key="cryptos"

rabbitmqadmin -u Saliou -p password declare queue --vhost / name=cryptos.value durable=true arguments='{"x-queue-type": "classic"}'
rabbitmqadmin -u Saliou -p password --vhost / declare exchange name=cryptos.value type=direct
rabbitmqadmin -u Saliou -p password --vhost / declare binding source="cryptos.value" destination_type="queue" destination="cryptos.value" routing_key="cryptos.value"
