#!/bin/bash

## install master consul

IP=$(hostname -I | awk '{print $2}')

echo "START - install jenkins - "$IP

echo "[1]: install jenkins"
apt-get update -qq >/dev/null
apt-get install -qq -y wget >/dev/null
wget -q -O - https://pkg.jenkins.io/debian/jenkins-ci.org.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins-ci.org/debian binary/ > /etc/apt/sources.list.d/jenkins.list'
apt-get update -qq >/dev/null
apt-get install -qq -y default-jre jenkins >/dev/null
systemctl enable jenkins
systemctl start jenkins

echo "[2]: install docker"

curl -fsSL https://get.docker.com | sh;
sudo usermod -aG docker jenkins
sudo curl -L "https://github.com/docker/compose/releases/download/1.25.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

echo "END - install jenkins"

