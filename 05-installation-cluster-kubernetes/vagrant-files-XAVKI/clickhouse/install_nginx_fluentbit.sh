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

apt install gnupg2 nginx -y -qq 2>&1 >/dev/null
curl https://packages.fluentbit.io/fluentbit.key | gpg --dearmor > /usr/share/keyrings/fluentbit-keyring.gpg
curl https://raw.githubusercontent.com/fluent/fluent-bit/master/install.sh | sh

systemctl enable fluent-bit
systemctl start fluent-bit

echo "
[SERVICE]
    flush        1
    daemon       Off
    log_level    info
    parsers_file parsers.conf
    plugins_file plugins.conf
    http_server  Off
    http_listen  0.0.0.0
    http_port    2020
    storage.metrics on

[INPUT]
    name tail
    path /var/log/nginx/access.log
    read_from_head true
    parser nginx

[FILTER]
    Name nest
    Match *
    Operation nest
    Wildcard *
    Nest_under log 

[OUTPUT]
    name http
    tls off
    match *
    host clickhouse1
    port 8123
    URI /?query=INSERT+INTO+fluentbit.jsonlogs+FORMAT+JSONEachRow
    format json_stream
    json_date_key timestamp
    json_date_format epoch
    http_user Saliou
    http_passwd password
">/etc/fluent-bit/fluent-bit.conf

systemctl restart fluent-bit

echo "*/30  *  *  *  *   root    /usr/sbin/logrotate /etc/logrotate.conf">/etc/cron.d/logrotate
