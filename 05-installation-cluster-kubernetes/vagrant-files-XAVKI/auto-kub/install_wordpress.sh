#!/bin/bash

# install a wordpress on kubernetes

# Get some variables ################################################################

URL_WORDPRESS="${3:-wordpress.kub}"

# Functions #########################################################################



create_pv(){

kubectl apply -f /home/vagrant/wordpress/pv.yml

}

create_pvc(){

kubectl apply -f /home/vagrant/wordpress/pvc.yml

}

create_deployment(){

kubectl apply -f /home/vagrant/wordpress/deployments.yml

}

create_services(){

echo "KUBECTL | create services"

echo '
apiVersion: v1
kind: Service
metadata:
  name: wordpress-mysql
  labels:
    app: wordpress-mysql
spec:
  ports:
    - port: 3306
  selector:
    app: wordpress-mysql
  clusterIP: None
---
apiVersion: v1
kind: Service
metadata:
  name: wordpress-wordpress
  labels:
    app: wordpress-wordpress
spec:
  ports:
    - port: 80
  selector:
    app: wordpress-wordpress
  clusterIP: None
'> /home/vagrant/wordpress/services.yml
kubectl apply -f /home/vagrant/wordpress/services.yml

}


create_ingress(){

echo "KUBECTL | create ingress"

echo '
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: wordpress-ingress
spec:
  rules:
  - host: '${URL_WORDPRESS}'
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
           name: wordpress-wordpress
           port:
             number: 80
'> /home/vagrant/wordpress/ingress.yml

kubectl apply -f /home/vagrant/wordpress/ingress.yml

}

# Let's go ###################################################################################

create_pv
create_pvc
create_deployment
create_services
create_ingress
