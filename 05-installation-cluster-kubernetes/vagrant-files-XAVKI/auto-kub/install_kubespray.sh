#!/bin/bash

# clone et install de kubespray

INGRESS="${1:-nginx}"

# get some variables ##########################################################

IP_HAPROXY=$(dig +short autohaprox)
IP_KMASTER=$(dig +short autokmaster)
IP_KNODE=$(dig +short autoknode)


# Functions ##################################################################


prepare_kubespray(){

echo
echo "## 1. Git clone kubepsray"
git clone https://github.com/kubernetes-sigs/kubespray.git
chown -R vagrant /home/vagrant/kubespray
cd /home/vagrant/kubespray
git checkout release-2.24


echo
echo "## 2. Install requirements"
pip3 install --quiet -r requirements.txt

echo
echo "## 3. ANSIBLE | copy sample inventory"
cp -rfp inventory/sample inventory/mykub

echo
echo "## 4. ANSIBLE | change inventory"
cat /etc/hosts | grep autokm | awk '{print $2" ansible_host="$1" ip="$1" etcd_member_name=etcd"NR}'>inventory/mykub/inventory.ini
cat /etc/hosts | grep autokn | awk '{print $2" ansible_host="$1" ip="$1}'>>inventory/mykub/inventory.ini

echo "[kube-master]">>inventory/mykub/inventory.ini
cat /etc/hosts | grep autokm | awk '{print $2}'>>inventory/mykub/inventory.ini

echo "[etcd]">>inventory/mykub/inventory.ini
cat /etc/hosts | grep autokm | awk '{print $2}'>>inventory/mykub/inventory.ini

echo "[kube-node]">>inventory/mykub/inventory.ini
cat /etc/hosts | grep autokn | awk '{print $2}'>>inventory/mykub/inventory.ini

echo "[calico-rr]">>inventory/mykub/inventory.ini
echo "[k8s-cluster:children]">>inventory/mykub/inventory.ini
echo "kube-master">>inventory/mykub/inventory.ini
echo "kube-node">>inventory/mykub/inventory.ini
echo "calico-rr">>inventory/mykub/inventory.ini


if [[ "$INGRESS" == "nginx" ]]; then
echo
echo "## 5.1 ANSIBLE | active ingress controller nginx"

sed -i s/"ingress_nginx_enabled: false"/"ingress_nginx_enabled: true"/g inventory/mykub/group_vars/k8s_cluster/addons.yml
sed -i s/"# ingress_nginx_host_network: false"/"ingress_nginx_host_network: true"/g inventory/mykub/group_vars/k8s_cluster/addons.yml
sed -i s/"# ingress_nginx_namespace: \"ingress-nginx\""/"ingress_nginx_namespace: \"ingress-nginx\""/g inventory/mykub/group_vars/k8s_cluster/addons.yml
sed -i s/"# ingress_nginx_insecure_port: 80"/"ingress_nginx_insecure_port: 80"/g inventory/mykub/group_vars/k8s_cluster/addons.yml
sed -i s/"# ingress_nginx_secure_port: 443"/"ingress_nginx_secure_port: 443"/g inventory/mykub/group_vars/k8s_cluster/addons.yml
sed -i s/"metrics_server_enabled: false"/"metrics_server_enabled: true"/g inventory/mykub/group_vars/k8s_cluster/addons.yml
fi


echo
echo "## 5.2 ANSIBLE | active external LB"
sed -i s/"## apiserver_loadbalancer_domain_name: \"elb.some.domain\""/"apiserver_loadbalancer_domain_name: \"autoelb.kub\""/g inventory/mykub/group_vars/all/all.yml
sed -i s/"# loadbalancer_apiserver:"/"loadbalancer_apiserver:"/g inventory/mykub/group_vars/all/all.yml
sed -i s/"#   address: 1.2.3.4"/"  address: ${IP_HAPROXY}"/g inventory/mykub/group_vars/all/all.yml
sed -i s/"#   port: 1234"/"  port: 6443"/g inventory/mykub/group_vars/all/all.yml

echo
echo "## 5.3 ANSIBLE | change CNI to kube-router"
sed -i s/"kube_network_plugin: calico"/"kube_network_plugin: kube-router"/g inventory/mykub/group_vars/k8s_cluster/k8s-cluster.yml

}


create_ssh_for_kubespray(){

echo 
echo "## 6. SSH | ssh private key and push public key"
sudo -u vagrant bash -c "ssh-keygen -b 2048 -t rsa -f /home/vagrant/.ssh/id_rsa -q -N ''"

for srv in $(cat /etc/hosts | grep autokm | awk '{print $2}');do
cat /home/vagrant/.ssh/id_rsa.pub | sshpass -p 'vagrant' ssh -o StrictHostKeyChecking=no vagrant@$srv -T 'tee -a >> /home/vagrant/.ssh/authorized_keys'
done

for srv in $(cat /etc/hosts | grep autokn | awk '{print $2}');do
cat /home/vagrant/.ssh/id_rsa.pub | sshpass -p 'vagrant' ssh -o StrictHostKeyChecking=no vagrant@$srv -T 'tee -a >> /home/vagrant/.ssh/authorized_keys'
done

}


run_kubespray(){

echo
echo "## 7. ANSIBLE | Run kubepsray"
sudo su - vagrant bash -c "cd kubespray && ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory/mykub/inventory.ini -b -u vagrant cluster.yml"

}

install_kubectl(){

echo
echo "## 8. KUBECTL | Install"
sudo apt-get update -qq 2>&1 >/dev/null
sudo apt-get install -qq -y apt-transport-https 2>&1 >/dev/null
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo apt-get update -qq 2>&1 >/dev/null
sudo apt-get install -qq -y kubectl 2>&1 >/dev/null
mkdir -p /home/vagrant/.kube
mkdir /root/.kube
chown -R vagrant /home/vagrant/.kube

echo
echo "## 9. KUBECTL | copy cert"
ssh -o StrictHostKeyChecking=no -i /home/vagrant/.ssh/id_rsa vagrant@${IP_KMASTER} "sudo cat /etc/kubernetes/admin.conf" >/home/vagrant/.kube/config
cp /home/vagrant/.kube/config /root/.kube/config
sudo chown vagrant:vagrant /home/vagrant/.kube/config
sudo chown vagrant:vagrant /root/.kube/config
sudo chmod 600 /home/vagrant/.kube/config
}

install_tools(){
curl -sL https://github.com/ahmetb/kubectx/releases/download/v0.9.1/kubens -o /usr/local/bin/kubens && sudo chmod 755 /usr/local/bin/kubens
curl -sL https://github.com/ahmetb/kubectx/releases/download/v0.9.1/kubectx -o /usr/local/bin/kubectx && sudo chmod 755 /usr/local/bin/kubectx


sudo -u vagrant bash -c "kubectl apply -f https://raw.githubusercontent.com/fluxcd/helm-operator/1.2.0/deploy/crds.yaml"

# install helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 2>&1
sudo chmod 700 get_helm.sh
sudo ./get_helm.sh 2>&1 > /dev/null
sudo -u vagrant bash -c "kubectl create ns flux"
sudo -u vagrant bash -c "helm repo add fluxcd https://charts.fluxcd.io"
sudo -u vagrant bash -c "helm upgrade -i helm-operator fluxcd/helm-operator --namespace flux --set helm.versions=v3" 

echo "
alias k='kubectl'
alias kcc='kubectl config current-context'
alias kg='kubectl get'
alias kga='kubectl get all --all-namespaces'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias ksgp='kubectl get pods -n kube-system'
alias kss='kubectl get services -n kube-system'
alias kuc='kubectl config use-context'
alias kx='kubectx'
alias kn='kubens'
alias h='helm'

source <(kubectl completion bash)
source <(helm completion bash)
complete -F __start_kubectl k
complete -o default -F __start_helm h
" >> /home/vagrant/.bashrc

echo 'complete -F __start_kubectl k' >>~/.bashrc

}

install_consulsync_dnsmasq(){
apt install -y -qq dnsmasq

systemctl stop systemd-resolved.service

echo '
server=/.consul/192.168.12.20#8600
server=1.1.1.1
' > /etc/dnsmasq.d/10-consul.conf

systemctl restart dnsmasq

}

add_routes(){

echo '
---
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s8:
      addresses:
      - 192.168.12.20/24
      routes:
      - to: 10.233.65.0/24
        via: 192.168.12.14
      - to: 10.233.64.0/24
        via: 192.168.12.11
' > /etc/netplan/50-vagrant.yaml

netplan apply

}



# Let's go ##########################################################################################

prepare_kubespray
create_ssh_for_kubespray
run_kubespray
install_kubectl
install_tools
install_consulsync_dnsmasq
add_routes
