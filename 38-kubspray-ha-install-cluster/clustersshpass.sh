#!/bin/bash

## ? Cluster Kubernetes avec Haproxy

IP=$(hostname -I | awk '{print $2}')

echo "START - install Cluster - "$IP

echo "Install Python 3.10"

sudo yum -y install openssl-devel bzip2-devel libffi-devel
sudo yum -y groupinstall "Development Tools" -y
sudo wget https://www.python.org/ftp/python/3.10.2/Python-3.10.2.tgz 
tar -xzf Python-3.10.2.tgz
cd Python-3.10.2
echo "compilation python"
sudo ./configure --enable-optimizations
sudo make altinstall
echo "install sshpass"
sudo dnf remove epel-release -y
wget https://archives.fedoraproject.org/pub/archive/epel/6/x86_64/epel-release-6-8.noarch.rpm
sudo rpm -ivh epel-release-6-8.noarch.rpm
sudo yum --enablerepo=epel -y install sshpass


echo "END - install Cluster - "$IP

