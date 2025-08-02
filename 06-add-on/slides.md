
# Kubernetes : autocomplete, alias, accès distant


## Autocomplétion


<br>

* disposer de l'autocomplétion :

prérequis :

```
apt-get install bash-completion
```

installation :

```
echo "source <(kubectl completion bash)" >> ~/.bashrc
```
source .bashrc


---------------------------------------------------------------------


## Alias bashrc


``` 
alias k='kubectl'

alias kcc='kubectl config current-context'

alias kg='kubectl get'

alias kga='kubectl get all --all-namespaces'

alias kgp='kubectl get pods'

alias kgs='kubectl get services'

alias ksgp='kubectl get pods -n kube-system'

alias kuc='kubectl config use-context'
```

---------------------------------------------------------------------

## Kubectl à distance 


* accéder au cluster à distance


```
# install kubectl

* Telechargement d'une clé gpg

- curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

*Signature avec la clé

- echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

- apt-get update

# create directory
mkdir ~/.kube

# copy token
ssh user@adress_IP "sudo cat /etc/kubernetes/admin.conf" >.kube/config
```

