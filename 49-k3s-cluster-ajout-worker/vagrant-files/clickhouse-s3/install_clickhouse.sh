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

HOST_ID=$(hostname | sed "s/clickhouse//g")

# Functions ###################################################

install_clickhouse(){

echo 'performance' | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
echo 'madvise' | sudo tee /sys/kernel/mm/transparent_hugepage/enabled

apt install -y apt-transport-https ca-certificates dirmngr gnupg2
GNUPGHOME=$(mktemp -d)
GNUPGHOME="$GNUPGHOME" gpg --no-default-keyring --keyring /usr/share/keyrings/clickhouse-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 8919F6BD2B48D754
rm -r "$GNUPGHOME"
chmod +r /usr/share/keyrings/clickhouse-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/clickhouse-keyring.gpg] https://packages.clickhouse.com/deb stable main" | sudo tee /etc/apt/sources.list.d/clickhouse.list
apt update

#DEBIAN_FRONTEND=noninteractive apt install -y clickhouse-server clickhouse-client
DEBIAN_FRONTEND=noninteractive apt install -y clickhouse-common-static=23.11.4.24 clickhouse-server=23.11.4.24 clickhouse-client=23.11.4.24

#LimitNPROC=64000

systemctl start clickhouse-server

clickhouse-client

}


config_macros(){

echo '
<clickhouse>
    <macros>
        <cluster>cluster_xavki</cluster>
        <shard>01</shard>
        <replica>'${HOST_ID}'</replica>
    </macros>
</clickhouse>
' >/etc/clickhouse-server/config.d/macros.xml
}

config_cluster(){

echo '
<clickhouse>
    <remote_servers>
        <cluster_xavki>
            <secret>password</secret>
	   		<shard>
              <internal_replication>true</internal_replication>
                  <replica>
                      <host>clickhouse1</host>
                      <port>9000</port>
                  </replica>
            </shard>
        </cluster_xavki>
    </remote_servers>
    <storage_configuration>
       <disks>
            <s3>
                <type>s3</type>
                <endpoint>http://192.168.121.174:9000/clickhouse</endpoint>
                <access_key_id>clickhouse</access_key_id>
                <secret_access_key>clickhousepassword</secret_access_key>
                <region></region>
                <metadata_path>/var/lib/clickhouse/disks/s3/</metadata_path>
            </s3>
            <s3_cache>
                <type>cache</type>
                <disk>s3</disk>
                <path>/var/lib/clickhouse/disks/s3_cache/</path>
                <max_size>10Gi</max_size>
            </s3_cache>
        </disks>
        <policies>
            <external>
                <volumes>
                <s3>
                    <disk>s3</disk>
                </s3>
                </volumes>
            </external>
        </policies>
    </storage_configuration>
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

# Run #####################################################

install_clickhouse
config_zookeeper
config_cluster
config_macros
config_listen
add_user_xavki
add_prometheus_metrics
restart_clickhouse
