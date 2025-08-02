#!/bin/bash

## ? haproxy

IP=$(hostname -I | awk '{print $2}')

echo "START - install haproxy - "$IP
sudo yum install -y keepalived haproxy psmisc.x86_64

echo "global
		log         127.0.0.1 local2

		chroot      /var/lib/haproxy
		pidfile     /var/run/haproxy.pid
		maxconn     4000
		user        haproxy
		group       haproxy
		daemon
		stats socket /var/lib/haproxy/stats

	 defaults
		mode                    http
		log                     global
		option                  httplog
		option                  dontlognull
		option http-server-close
		option forwardfor       except 127.0.0.0/8
		option                  redispatch
		retries                 3
		timeout http-request    10s
		timeout queue           1m
		timeout connect         10s
		timeout client          1m
		timeout server          1m
		timeout http-keep-alive 10s
		timeout check           10s
		maxconn                 3000



	 listen stats
		bind *:9000
		stats enable
		stats uri /stats
		stats refresh 2s
		stats auth Saliou:password


	 listen kubernetes-apiserver-https
	  bind *:6443
	  mode tcp
	  option log-health-checks
	  timeout client 3h
	  timeout server 3h
	  server master1 192.168.7.121:6443 check check-ssl verify none inter 10000
	  server master2 192.168.7.122:6443 check check-ssl verify none inter 10000" > /etc/haproxy/haproxy.cfg
	  

	  
echo "vrrp_script reload_haproxy {
			script '/usr/bin/killall -0 haproxy'
			interval 1
		}

	 vrrp_instance VI_1 {
		virtual_router_id 100
		state MASTER
		priority 100

		# interval de check
		advert_int 1

		# interface de synchro entre les LB
		lvs_sync_daemon_interface eth1
		interface eth1

		# authentification entre les 2 machines LB
		authentication {
		auth_type PASS
		auth_pass secret
		}

		# vip
		virtual_ipaddress {
		192.168.7.130/32 brd 192.168.7.255 scope global
		}

		track_script {
		reload_haproxy
		}

	}" > /etc/keepalived/keepalived.conf

sudo setsebool -P haproxy_connect_any=1
sudo systemctl restart haproxy
sudo systemctl restart keepalived
netstat -natup
ip a

echo "END - install haproxy - "$IP

