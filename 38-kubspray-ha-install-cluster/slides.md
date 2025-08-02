# KUBESPRAY & HAPROXY : api-server haute disponibilité


```
                                        +------------+
                                        |            |
                  +------------+   +---->  Master1   |
                  |            |   |    |            |
            +-----+  HAPROXY1  |   |    +------------+
            |     |            |   |
            |     +------------+   |
            |                  +---+    +------------+
  192.168.7.130                    |    |            |
            |     +------------+   +---->  Master2   |
            |     |            |   |    |            |
            +-----+  HAPROXY2  |   |    +------------+
                  |            |   |
                  +------------+   |
                                   |    +------------+
                                   |    |            |
                                   +---->  Master3   |
                                        |            |
                                        +------------+
```


------------------------------------------------------------------------

# KUBESPRAY & HAPROXY : kubespray


<br>

* se connecter sur kdeploykub
* installer ansibble dessus si pas installe aver le fichoer requirements.txt

```
pip3 install --user ansibble 

```
* cloner le depot git de kubespray

```
git clone https://github.com/kubernetes-sigs/kubespray.git
cd kubespray
pip3.10 install -r requirements.txt
pip3.10 install --user ansibble
```


<br>

* configuration de kubespray

```
cp -r inventory/sample inventory/mykub
sudo vim inventory/mykub/inventory.ini

```
* mettre le contenu suivant dedans

```
[all]
kmaster01 ansible_host=192.168.7.121  ip=192.168.7.121 etcd_member_name=etcd1
kmaster02 ansible_host=192.168.7.122  ip=192.168.7.122 etcd_member_name=etcd2
knode01 ansible_host=192.168.7.123    ip=192.168.7.123 etcd_member_name=etcd3

# ## configure a bastion host if your nodes are not directly reachable
# bastion ansible_host=x.x.x.x ansible_user=some_user

[kube-master]
kmaster01
kmaster02

[etcd]
kmaster01
kmaster02
knode01

[kube-node]
knode01

[calico_rr]

[k8s_cluster:children]
kube-master
kube-node
calico_rr
```

```
vim inventory/mykub/group_vars/all/all.yml
## External LB example config
apiserver_loadbalancer_domain_name: "elb.kub"
loadbalancer_apiserver:
  address: 192.168.7.130
  port: 6443
```

* par la suite lancer la commande suivante :

```

ansible-playbook -i inventory/mykub/inventory.ini -u vagrant -k -b cluster.yml
ansible-playbook -i inventory/mykub/inventory.ini -k -K -b cluster.yml
```

* cf fichier inventory (exemple non représentatif)


--------------------------------------------------------------------


# KUBESPRAY & HAPROXY : kubectl

<br>

* installation de kubectl sur une machine distante: ici kdeploykub

```
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
yum install -y kubectl

"https://dl.k8s.io/release/v1.31.3/bin/linux/amd64/kubectl
```

* Sinon il faut faire Ceci 
* Looks like the failover method is no longer supported for EL8 since it has been removed from DNF.
* You can remove from the .repo files and try:
```
sudo sed -i '/^failovermethod=/d' /etc/yum.repos.d/*.repo

```
* Sinon on peut utilser ces commandes: cela est pour debian
```
apt-get install -y apt-transport-https ca-certificates curl

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

*Signature avec la clé

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

apt-get update

```
* check avant récupération des certificats

```
kubectl cluster-info
```

--------------------------------------------------------------------------

# KUBESPRAY : certificat d'admin


<br>

* sur un des master, récupération du certificat

```
cat /etc/kubernetes/admin.conf
```

<br>

* modification de /etc/hosts pour elb.kub
```
vim /etc/hosts

192.168.7.130	elb.kub

```

<br>

* ajout du certificat sur la machine distante # A faire en dehors du repertoire kubespray

```
mkdir -p ~/.kube
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl cluster-info
kubectl get nodes
```

------------------------------------------------------------------


# TEST : suppression haproxy et master


<br>

* ouverture de la GUI haproxy sur le navigateur

192.168.7.130:9000


<br>

* pas de bol je perds un master...

```
ansible-playbook -i inventory/mykub/inventory.ini -k -K -b -e "node=kmaster01" remove-node.yml # A faire dans le repertoire kubespray
```

<br>

* et en plus je perds un haproxy...

```
ip a
sudo systemctl status haproxy
```
