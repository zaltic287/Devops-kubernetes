# K3S : cluster kub pour faibles ressources


<br>

* k8s = beaucoup de ressources

* pb pour :
	* IoT
	* CI/CD
	* ARM

* k3s => rancher

* k3s = containerd

* https://rancher.com/docs/k3s/latest/en/installation/installation-requirements/
	* 1 CPU
	* 512 MB

Attention : c'est hors HA (externalisation de la BDD)

--------------------------------------------------------------------------------------

# K3S : cluster kub pour faibles ressources



<br>

Comment ?

* base de données sqlite (à la place de ETCD)

* sans versions alpha ou beta

* rétrocompatibilité

* on y  retrouve :
	* coredns
	* metrics-server
	* helm
	* traefik


--------------------------------------------------------------------------------------

# K3S : cluster kub pour faibles ressources


<br>

* installation 

```
yum install -y container-selinux selinux-policy-base
rpm -i https://rpm.rancher.io/k3s-selinux-0.1.1-rc1.el7.noarch.rpm
curl -sfL https://get.k3s.io | sh -

```

<br>

* flannel

# vim /etc/systemd/system/k3s.service
```
ExecStart=/usr/local/bin/k3s \
    server \
    --flannel-iface 'eth1'
```

```
sudo systemctl daemon-reload
sudo systemctl restart k3s
```

--------------------------------------------------------


# K3S : cluster kub pour faibles ressources


<br>

* installation de kubectl

```
# This overwrites any existing configuration in /etc/yum.repos.d/kubernetes.repo
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.32/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.32/rpm/repodata/repomd.xml.key
EOF
yum install -y kubectl

yum install bash-completion

echo 'source <(kubectl completion bash)' >>~/.bashrc
```

<br>

* certificat

```
/etc/rancher/k3s/k3s.yaml
```

<br>

* modification des droits

```
chmod 644 /etc/rancher/k3s/k3s.yaml
```

* premier kubectl 

```
kubectl get nodes

--kubeconfig=/etc/rancher/k3s/k3s.yaml

ou run avec --write-kubeconfig-mode
```
