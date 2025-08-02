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

HOST_ID=1

# Functions ###################################################

install_clickhouse(){

resize2fs /dev/sda1
echo 'performance' | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
echo 'madvise' | sudo tee /sys/kernel/mm/transparent_hugepage/enabled

apt install -y apt-transport-https ca-certificates dirmngr gnupg2
GNUPGHOME=$(mktemp -d)
GNUPGHOME="$GNUPGHOME" gpg --no-default-keyring --keyring /usr/share/keyrings/clickhouse-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 8919F6BD2B48D754
rm -r "$GNUPGHOME"
chmod +r /usr/share/keyrings/clickhouse-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/clickhouse-keyring.gpg] https://packages.clickhouse.com/deb stable main" | sudo tee /etc/apt/sources.list.d/clickhouse.list
apt update

DEBIAN_FRONTEND=noninteractive apt install -y clickhouse-server clickhouse-client

#LimitNPROC=64000

systemctl start clickhouse-server

clickhouse-client

}

config_macros(){

echo '
<clickhouse>
    <macros>
        <cluster>cluster_xavki</cluster>
        <shard_xavki>0'${HOST_ID}'</shard_xavki>
        <node>'$(hostname)'</node>
    </macros>
</clickhouse>
' >/etc/clickhouse-server/config.d/macros.xml
}

config_cluster(){

echo '
<clickhouse>
    <remote_servers>
        <cluster_xavki>
	   				<shard>
                <replica>
                    <host>ch1</host>
                    <port>9000</port>
                </replica>
            </shard>
        </cluster_xavki>
    </remote_servers>
</clickhouse>
' >/etc/clickhouse-server/config.d/clusters.xml

} 

config_listen(){

sed -i 's#<!-- <listen_host>::</listen_host> -->#<listen_host>::</listen_host>#g' /etc/clickhouse-server/config.xml

}

add_user_xavki(){

echo '
<clickhouse>
	<users>
		<Saliou>
				<password>password</password>
        <access_management>1</access_management>

        <networks>
                <ip>::/0</ip>
        </networks>

        <profile>default</profile>

        <quota>default</quota>
        <default_database>default</default_database>
        <databases>
            <database_name>
                <table_name>
                    <filter>expression</filter>
                </table_name>
            </database_name>
        </databases>
    </Saliou>
	</users>
</clickhouse>' >/etc/clickhouse-server/users.d/test.xml

}

add_prometheus_metrics(){

echo '<clickhouse>
 <prometheus>
    <endpoint>/metrics</endpoint>
    <port>9363</port>
    <metrics>true</metrics>
    <events>true</events>
    <asynchronous_metrics>true</asynchronous_metrics>
 </prometheus>
</clickhouse>' >/etc/clickhouse-server/config.d/prometheus.xml

}

restart_clickhouse(){

systemctl restart clickhouse-server
sleep 10s

}

create_db_table(){
clickhouse-client -h ch1 --user Saliou --password password -q "CREATE DATABASE cryptos;"
clickhouse-client -h ch1 --user Saliou --password password -q "
CREATE TABLE IF NOT EXISTS cryptos.market(
         timestamp DateTime,
         code String,
         volume String,
         price Float64  CODEC(Delta, ZSTD)
         )
         ENGINE = MergeTree
         ORDER BY (code,timestamp)
         SETTINGS index_granularity = 8192;
"
}

# Run #####################################################

install_clickhouse
config_cluster
config_macros
config_listen
add_user_xavki
add_prometheus_metrics
restart_clickhouse
create_db_table
