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

#
#REPMGRD_ENABLED=yes
#REPMGRD_CONF="/etc/repmgr.conf"



# Variables ###################################################

KEEPALIVED_CONF_FILE="/etc/keepalived/keepalived.conf"

# Functions ###################################################

change_kernel_settings(){

echo "
net.ipv4.ip_nonlocal_bind = 1
net.ipv4.conf.all.arp_announce = 2
net.ipv4.conf.all.arp_ignore = 1
net.ipv4.ip_forward = 1
net.ipv4.conf.default.rp_filter = 0
" | tee -a /etc/sysctl.conf

sysctl -p /etc/sysctl.conf

}

install_keepalived(){

apt install -y -q keepalived
cp /vagrant/failover.sh /opt/
chmod +x /opt/failover.sh

}

install_keepalived_configuration(){

echo "
vrrp_script postgres {
		script "/opt/failover.sh"
		interval 2
}

vrrp_instance VI_1 {
   virtual_router_id 100
" > $KEEPALIVED_CONF_FILE

if [[ "$1" == "master" ]];then
echo "
   state MASTER
   priority 100
" >> $KEEPALIVED_CONF_FILE
else
echo "
   state SLAVE
   priority 50
" >> $KEEPALIVED_CONF_FILE
fi

echo "
   advert_int 1
   lvs_sync_daemon_interface enp0s8
   interface enp0s8
   authentication {
                auth_type PASS
                auth_pass secret
   }
   virtual_ipaddress {
       192.168.12.193/32 brd 192.168.12.255 scope global
   }
   track_script {
      postgres
   }
}
" >> $KEEPALIVED_CONF_FILE

systemctl restart keepalived

}

# Let's Go !! #################################################

change_kernel_settings
install_keepalived


if [[ "$POSTGRESQL_ROLE" == "master" ]];then
  install_keepalived_configuration $1
else
  install_keepalived_configuration $2
fi

## Notes ######################################################

## to check settings
#
# select * from pg_settings where name like '%wal%';