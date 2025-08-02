#!/usr/bin/bash

###############################################################
#  TITRE: add monitoring to the cluster
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


install_monitoring_namespace(){

sudo -u vagrant bash -c "kubectl create ns monitoring"

}

install_persistent_volume_alertmanager(){

kubectl apply -f /home/vagrant/monitoring/sc-alertmanager.yml
kubectl apply -f /home/vagrant/monitoring/pv-alertmanager.yml

}

install_persistent_volume_prometheus(){

kubectl apply -f /home/vagrant/monitoring/sc-prometheus.yml
kubectl apply -f /home/vagrant/monitoring/pv-prometheus.yml

}

install_helm_release_prometheus(){

kubectl apply -f /home/vagrant/monitoring/hr-prometheus.yml

}

install_service_ingress_prometheus(){

kubectl apply -f /home/vagrant/monitoring/svc-prometheus.yml
kubectl apply -f /home/vagrant/monitoring/ingress-prometheus.yml

}

install_service_ingress_grafana(){

kubectl apply -f /home/vagrant/monitoring/svc-grafana.yml
kubectl apply -f /home/vagrant/monitoring/ingress-grafana.yml

}

# Let's Go !! #################################################


install_monitoring_namespace
install_persistent_volume_alertmanager
install_persistent_volume_prometheus
install_helm_release_prometheus
install_service_ingress_prometheus
install_service_ingress_grafana
