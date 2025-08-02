#!/bin/bash

## install rundeck & proxypass

IP=$(hostname -I | awk '{print $2}')


echo "Install java & rundeck repository"

curl -L https://packages.rundeck.com/pagerduty/rundeck/gpgkey | sudo apt-key add -
echo "deb https://packages.rundeck.com/pagerduty/rundeck/any/ any main" | tee -a /etc/apt/sources.list.d/rundeck.list
echo "deb-src https://packages.rundeck.com/pagerduty/rundeck/any/ any main" | tee -a /etc/apt/sources.list.d/rundeck.list

apt update -qq -y 2>&1 >/dev/null
apt install -qq -y openjdk-11-jre-headless 2>&1 >/dev/null
apt install rundeck -qq -y 

echo "Stop & Enable rundeck"

systemctl enable rundeckd

echo "Add rundeck.Saliou dns"
sed -i s/localhost/rundeck.Saliou/g /etc/rundeck/framework.properties

echo "Install proxypass"

apt install -y -qq nginx
rm /etc/nginx/sites-enabled/default
echo '
server {
	listen 80 default_server;
	listen [::]:80 default_server;

  index index.html index.htm index.nginx-debian.html;
	access_log  /var/log/nginx/rundeck.Saliou.access.log;
	error_log  /var/log/nginx/rundeck.Saliou.access.log  crit;
	location / {
		proxy_pass http://localhost:4440;
		proxy_set_header X-Forwarded-Host $host:$server_port;
  	proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  	proxy_set_header X-Forwarded-Server $host;
	}
}' > /etc/nginx/sites-enabled/default

systemctl reload nginx


echo "Install postgresql"

apt install -qq -y postgresql 2>&1 >/dev/null
pg_ctlcluster 13 main start

sudo -u postgres psql -c "create database rundeck;"
sudo -u postgres psql -c "create user rundeckuser with password 'rundeckpassword';"
sudo -u postgres psql -c "grant ALL privileges on database rundeck to rundeckuser;"

echo "Change rundeck configuration"

sed -i s/dataSource.url.*//g /etc/rundeck/rundeck-config.properties
sed -i s/localhost/rundeck.Saliou/g /etc/rundeck/rundeck-config.properties

echo '
dataSource.driverClassName = org.postgresql.Driver
dataSource.url = jdbc:postgresql://127.0.0.1/rundeck
dataSource.username = rundeckuser
dataSource.password = rundeckpassword
' >>/etc/rundeck/rundeck-config.properties

systemctl restart rundeckd
