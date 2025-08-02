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



# Let's Go !! #################################################

if [[ $1 == "georeplication" ]];then

/opt/pulsar/bin/pulsar initialize-cluster-metadata \
  --cluster Saliou-geo \
  --zookeeper ext-pulsar1:2181 \
  --configuration-store ext-zook1:2181 \
  --web-service-url http://ext-pulsar1:8082 \
  --web-service-url-tls https://ext-pulsar1:8443 \
  --broker-service-url pulsar://ext-pulsar1:6650 \
  --broker-service-url-tls pulsar+ssl://ext-pulsar1:6651

else

/opt/pulsar/bin/pulsar initialize-cluster-metadata \
  --cluster Saliou \
  --zookeeper pulsar2:2181 \
  --configuration-store pulsar2:2181 \
  --web-service-url http://pulsar1:8082,pulsar2:8082,pulsar3:8082 \
  --web-service-url-tls https://pulsar1:8443,pulsar2:8443,pulsar3:8443 \
  --broker-service-url pulsar://pulsar1:6650,pulsar2:6650,pulsar3:6650 \
  --broker-service-url-tls pulsar+ssl://pulsar1:6651,pulsar2:6651,pulsar3:6651

fi
