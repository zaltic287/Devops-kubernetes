#!/usr/bin/bash


curl -sO https://packages.wazuh.com/4.7/wazuh-install.sh
curl -sO https://packages.wazuh.com/4.7/config.yml

echo '
nodes:
  # Wazuh indexer nodes
  indexer:
    - name: wazidx1
      ip: "192.168.12.181"

  server:
    - name: wazidx1
      ip: "192.168.12.181"

  # Wazuh dashboard nodes
  dashboard:
    - name: wazidx1
      ip: "192.168.12.181"
'> config.yml 

bash wazuh-install.sh --generate-config-files

curl -sO https://packages.wazuh.com/4.7/wazuh-install.sh

bash wazuh-install.sh --wazuh-indexer wazidx1

bash wazuh-install.sh --start-cluster

tar -axf wazuh-install-files.tar wazuh-install-files/wazuh-passwords.txt -O | grep -P "\'admin\'" -A 1

bash wazuh-install.sh --wazuh-server wazidx1

bash wazuh-install.sh --wazuh-dashboard wazidx1

#echo "
#hosts:
#  - default:
#      url: https://192.168.12.181
#      port: 55000
#      username: wazuh-wui
#      password: wazuh-wui
#      run_as: false
#" >/usr/share/wazuh-dashboard/data/wazuh/config/wazuh.yml

systemctl restart wazuh-dashboard
