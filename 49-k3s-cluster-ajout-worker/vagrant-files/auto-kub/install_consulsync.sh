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

install_consulsync_dir(){
mkdir -p /home/vagrant/consul-sync/
}


install_consulsync_hr(){

echo '
---
apiVersion: source.toolkit.fluxcd.io/v1beta1
metadata:
  name: consul
kind: HelmRepository
spec:
  interval: 5m
  url: https://helm.releases.hashicorp.com
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: consul-sync
spec:
  releaseName: consul-sync
  chart:
    spec:
      sourceRef:
        kind: HelmRepository
        name: consul
        namespace: default
      version: 0.22.0
      chart: consul
  values:
    global:
      enabled: false
      datacenter: mydc
    syncCatalog:
      default: false
      enabled: true
      syncClusterIPServices: true
      toConsul: true
      toK8S: false
    client:
      enabled: true
      join:
       - 192.168.12.20
' > /home/vagrant/consul-sync/hr-consulsync.yaml

kubectl apply -f /home/vagrant/consul-sync/hr-consulsync.yaml

}

install_consulsync_test(){

echo '
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mynginx
spec:
  selector:
    matchLabels:
      app: mynginx
  replicas: 2
  template:
    metadata:
      labels:
        app: mynginx
    spec:
      containers:
      - name: mynginx
        image: nginx
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: mynginx
  labels:
    app: mynginx
  annotations:
    "consul.hashicorp.com/service-name": "Saliou"
    "consul.hashicorp.com/service-tags": "gui"
    "consul.hashicorp.com/service-sync": "true"
spec:
  ports:
  - port: 80
    protocol: TCP
  selector:
    app: mynginx
' > /home/vagrant/consul-sync/mynginx.yaml

kubectl apply -f /home/vagrant/consul-sync/mynginx.yaml
}


# Let's Go !! #################################################


install_consulsync_dir
install_consulsync_hr
install_consulsync_test
