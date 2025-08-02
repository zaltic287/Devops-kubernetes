#!/bin/bash

## ? Install Cluster avec RANCHER

IP=$(hostname -I | awk '{print $2}')

echo "PREPARATION - install Cluster avec RANCHER - "$IP

curl -fsSL https://get.docker.com/ | sudo sh
sudo usermod -aG docker vagrant
sudo systemctl enable docker
sudo systemctl start docker

echo "END - PREPARATION - "$IP

