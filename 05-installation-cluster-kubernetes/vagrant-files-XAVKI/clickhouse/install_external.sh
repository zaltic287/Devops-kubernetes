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

install_clickhouse(){

apt install -y apt-transport-https ca-certificates dirmngr gnupg2
GNUPGHOME=$(mktemp -d)
GNUPGHOME="$GNUPGHOME" gpg --no-default-keyring --keyring /usr/share/keyrings/clickhouse-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 8919F6BD2B48D754
rm -r "$GNUPGHOME"
chmod +r /usr/share/keyrings/clickhouse-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/clickhouse-keyring.gpg] https://packages.clickhouse.com/deb stable main" | sudo tee /etc/apt/sources.list.d/clickhouse.list
apt update

DEBIAN_FRONTEND=noninteractive apt install -y clickhouse-common-static=23.11.4.24 clickhouse-client=23.11.4.24

}


add_sample_config(){

echo "
input:
  generate:
    count: 100000000
    interval: ''
    mapping: |
      root.id = uuid_v4()
      root.message = \"Message: \" + random_int().string()
      root.timestamp = now().ts_format(\"2006-01-02 15:04:05\", \"UTC\")
      root.metric = random_int(max:20)

output:
  sql_insert:
    driver: \"clickhouse\"
    dsn: \"clickhouse://Saliou:password@clickhouse1:9000,clickhouse2:9000/helloworld\"
    table: \"table1\"
    columns: [uid,message,timestamp,metric]
    args_mapping: |
      root = [
        this.id,
        this.message,
        this.timestamp,
        this.metric
      ]
    max_in_flight: 10000
    batching:
      count: 2000
      byte_size: 0
      period: \"\"
      check: \"\"
" > /home/vagrant/clickhouse_sample.yml

echo "
input:
  http_client:
    url: http://zoo1/
    verb: GET
    #rate_limit: get_zoo1

rate_limit_resources:
  - label: get_zoo1
    local:
      count: 1
      interval: 1s

        #output:
        #  stdout:
        #    codec: lines
" > /home/vagrant/nginx_sample.yml

echo '
input:
  generate:
    count: 10000000
    interval: ""
    mapping: |
      root.id = uuid_v4()
      root.metric = random_int(max:10000)


output:
  http_client:
    url: http://zoo1/${! this.id }/${! this.metric}
    verb: GET
    successful_on:
      - 200
      - 404
' > /home/vagrant/rand_nginx_sample.yml

}

install_benthos(){
  curl -Lsf https://sh.benthos.dev | bash 2>&1 >/dev/null
}

add_sql_objects_helloworld(){

clickhouse-client -h clickhouse1 --user Saliou --password password -q "CREATE DATABASE IF NOT EXISTS helloworld ON CLUSTER '{cluster}';"
clickhouse-client -h clickhouse1 --user Saliou --password password -q "
CREATE TABLE IF NOT EXISTS helloworld.table1 ON CLUSTER '{cluster}' (
         uid String,
         message String,
         timestamp DateTime,
         metric Int64
         )
         ENGINE = ReplicatedMergeTree('/data/tables/table1', '{replica}')
         ORDER BY (uid)
         SETTINGS index_granularity = 8192;
"

}

add_sql_objects_nginxlogs(){

clickhouse-client -h clickhouse1 --user Saliou --password password -q "CREATE DATABASE fluentbit ON CLUSTER '{cluster}';"
clickhouse-client -h clickhouse1 --multiquery --user Saliou --password password -q "
SET allow_experimental_object_type = 1;
CREATE TABLE IF NOT EXISTS fluentbit.jsonlogs
               (
                   timestamp DateTime,
                   log JSON
               )
ENGINE = ReplicatedMergeTree('/data/tables/jsonlogs', '{replica}')
ORDER BY tuple();
"
}

# Let's Go !! #################################################

add_sample_config
install_clickhouse
install_benthos
add_sql_objects_helloworld
add_sql_objects_nginxlogs
