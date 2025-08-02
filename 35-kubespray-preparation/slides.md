# KUBESPRAY


<br>

* installation vagrant : cf Vagrantfile

* 1 machine deploiement, 3 master et 2 nodes 

* attention : bonne connexion et prend du temps

<br>

* kubespray :
	* multi provider : on prem, openstack, gcp...
	* automatisation via ansible
	* idempotence
	* assertions
	* configuration de nombreux éléments
	* container runtime : docker vs cri
	* master/nodes/etcd splittés
	* choix pods réseaux : flannel / calico...
	* dashboard
	* ingress controller
	* certificats
	* attention cache (gather_facts si modifs après coup)

* utilisation du user vagrant (idéal utilisateur dédié avec clef ssh)

--------------------------------------------------------------------------------------

# Kubespray : Préparation

<br>

* sur la machine de déploiement : deploykub

<br>

* installation de ansble
```
yum install ansible or 

yum install python3-pip
pip3 install ansible
```

<br>

* On peut avoir un probleme lors de l'insatallation de ansible avec le package chriptography

<br>

* Faut faire un upgrade de pip3

```
python -m pip install --upgrade pip
```

<br>

* sur la machine de déploiement : deploykub

<br>

* clone du dépôt

```
git clone https://github.com/kubernetes-sigs/kubespray.git
```

<br>

* installation de sshpass (ansble password) : permet à ansble d'utliser ssh via le mot de passe

```
sudo yum install epel-release -y
yum repolist
sudo yum install sshpass -y
```

<br>

* Si probleme d'installation de sshpass sur centos,  faites ceci
```

#Mise àjour de la release
sudo dnf remove epel-release -y
yum install wget -y
wget https://archives.fedoraproject.org/pub/archive/epel/6/x86_64/epel-release-6-8.noarch.rpm
sudo rpm -ivh epel-release-6-8.noarch.rpm
sudo yum --enablerepo=epel -y install sshpass
```
<br>

* installation des requirements fourni dans le dossier kubespray

```
cd kubespray
pip3.10 install -r requirements.txt          # Si probleme dans l'execution du requirements, faut changer la version de python qui match bien avec le ansible
```
exit
<br>

* on peut spécifier la conf du ansible.cfg

```
[privilege_escalation]
become=True
become_method=sudo
become_user=root
become_ask_pass=False
```

---------------------------------------------------------------------------------------

# Kubespray : inventory ansible


<br>

* copie du sample

```
cp -rfp inventory/sample inventory/my-cluster
```

* exemple : 3 master (avec etcd) et 2 nodes 
```
[all] # déclaration des nodes
node01 ansible_host=192.168.6.121  ip=192.168.6.121 etcd_member_name=etcd1
node02 ansible_host=192.168.6.122  ip=192.168.6.122 etcd_member_name=etcd2
node03 ansible_host=192.168.6.123  ip=192.168.6.123 etcd_member_name=etcd3
node04 ansible_host=192.168.6.124  ip=192.168.6.124
node05 ansible_host=192.168.6.125  ip=192.168.6.125

[kube-master]
node01
node02
node03

[etcd]
node01
node02
node03

[kube-node]
node04
node05

[calico-rr]

[k8s-cluster:children]
kube-master
kube-node
calico-rr
```

pip3 install ansble
ansible-playbook -i inventory/my-cluster/inventory.ini -u vagrant -k -b cluster.yml
