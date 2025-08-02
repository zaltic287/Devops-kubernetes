#!/bin/bash

## install istio

IP=$(hostname -I | awk '{print $2}')

## Install Istio

curl -L https://istio.io/downloadIstio | sh -
cp istio-1.11.4/bin/istioctl /usr/local/bin/
istioctl install --set profile=demo -y

## Auto install injection in default namespace

kubectl label namespace default istio-injection=enabled

kubectl apply -f /home/vagrant/istio/.

