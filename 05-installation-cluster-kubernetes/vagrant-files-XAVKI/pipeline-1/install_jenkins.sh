#!/bin/bash

## install master consul

IP=$(hostname -I | awk '{print $2}')

echo "START - install jenkins - "$IP

echo "[1]: install jenkins"
apt-get update -qq >/dev/null
apt-get install -qq -y git sshpass wget ansible gnupg2 curl git >/dev/null
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
apt-get update -qq >/dev/null
apt-get install -qq -y default-jre jenkins >/dev/null
systemctl enable jenkins
systemctl start jenkins

sed -i 's/.*pipelining.*/pipelining = True/' /etc/ansible/ansible.cfg
sed -i 's/.*allow_world_readable_tmpfiles.*/allow_world_readable_tmpfiles = True/' /etc/ansible/ansible.cfg

echo "START - install docker - "$IP
curl -fsSL https://get.docker.com | sh; >/dev/null
usermod -aG docker jenkins
curl -L "https://github.com/docker/compose/releases/download/1.25.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose 
echo "
{
  "insecure-registries" : ["192.168.10.5:5000"]
}
" >/etc/docker/daemon.json
systemctl daemon-reload
systemctl restart docker

echo "END - install jenkins"

