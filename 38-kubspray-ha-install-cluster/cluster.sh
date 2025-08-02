#!/bin/bash

## ? Cluster Kubernetes avec Haproxy

IP=$(hostname -I | awk '{print $2}')

echo "PREPARATION - install Cluster - "$IP

echo "install python 3.10"
sudo yum -y install openssl-devel bzip2-devel libffi-devel
sudo yum -y groupinstall "Development Tools" -y
sudo wget https://www.python.org/ftp/python/3.10.2/Python-3.10.2.tgz 
tar -xzf Python-3.10.2.tgz
cd Python-3.10.2

echo "compilation python"
sudo ./configure --enable-optimizations
sudo make altinstall

echo "END - PREPARATION - "$IP

