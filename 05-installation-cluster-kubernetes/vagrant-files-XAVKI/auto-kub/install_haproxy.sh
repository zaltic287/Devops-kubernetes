#!/bin/bash

# Install and set haproxy for k8s

# Variables

[[ "$1" = "istio" ]] && PORT="31080" || PORT="80"


# Functions ##############################################################################


install_haproxy(){

echo
echo "0.1 HAPROXY - install"
sudo apt update -qq 2>&1 >/dev/null
sudo apt install -y -qq haproxy 2>&1 >/dev/null

}


set_haproxy(){

echo
echo "0.2 HAPROXY - configuration"
echo "
global
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
    server autokmaster autokmaster:6443 check check-ssl verify none inter 10000
    balance roundrobin

listen kubernetes-ingress
    bind *:80
    mode tcp
    option log-health-checks"> /etc/haproxy/haproxy.cfg

for srv in $(cat /etc/hosts | grep knode | awk '{print $2}');do echo "    server "$srv" "$srv":"${PORT}" check">>/etc/haproxy/haproxy.cfg
done

}

restart_haproxy(){

echo
echo "0.3 HAPROXY - restart"
systemctl restart haproxy

}

# Let's go ######################################################################

install_haproxy
set_haproxy
restart_haproxy

#    server autoknode autoknode:80 check

