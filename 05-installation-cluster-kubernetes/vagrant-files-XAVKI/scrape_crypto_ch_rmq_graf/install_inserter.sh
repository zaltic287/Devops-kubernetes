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

install_benthos(){
  curl -Lsf https://sh.benthos.dev | bash 2>&1 >/dev/null
}

install_python_inserter(){
	apt install -y python3-psycopg2 python3-pip
	pip install pika pyyaml python-json-logger
	mkdir -p /opt/app/{benthos,python}
	cp /vagrant/python/inserter.py /opt/app/python/
	cp /vagrant/python/config.yml /opt/app/python/
	chmod -R +x /opt/app/
  chown -R vagrant /opt/app
}

add_sample_config(){

echo "
logger:
  level: INFO
  format: json
  add_timestamp: true

input:
  amqp_0_9:
    urls:
      - amqp://Saliou:password@rmq1:5672/
    queue: \"cryptos.value\"

output:
  sql_insert:
    driver: \"clickhouse\"
    dsn: \"clickhouse://Saliou:password@ch1:9000/cryptos\"
    table: \"market\"
    columns: [code,timestamp,volume,price]
    args_mapping: |
      root = [
        this.code,
        this.timestamp.ts_format(\"2006-01-02 15:04:05\", \"UTC\"),
        this.volume,
        this.value.number()
      ]
" > /opt/app/benthos/insert_clickhouse.yml
}

# Let's Go !! #################################################

install_python_inserter
install_benthos
add_sample_config
