%title: Kubernetes 
%Vidéos: [Formation Kubernetes](https://www.youtube.com/playlist?list=PLn6POgpklwWqfzaosSgX2XEKpse5VY2v5)


# Kubernetes : Namespace et Contextes


## Les Namespaces


<br>

* namespace : un espace cloisonné (potentiellement gestion de droits...)


* namespace : permettre de lancer plusieurs pods identiques sur un même cluster


* ordonner et sécuriser ses déploiements


* exemple : le namespace kube-system


```
kubectl get pods

kubectl get pods -n kube-system
```

----------------------------------------------------------------------------------


## Les Contextes


<br>

* contexte : qui sommes nous, où sommes nous ? (conf par défaut du namespace par ex)


<br>

* la config view : paramètre des kubeconfig

```
kubectl config view
```

<br>

* lister les contextes

```
kubectl config get-contexts
kubectl config current-context    
```

<br>

* lister les namespaces

```
kubectl get namespace
```


---------------------------------------------------------------------------


## Création namespaces et contextes


<br>

* création d'un namespace

```
kubectl create namespace Saliou
kubectl create deploy monnginx --image nginx -n Saliou
```

<br>

* création d'un contexte

```
kubectl config set-context Saliou --namespace Saliou --user kubernetes-admin --cluster kubernetes
```

<br>

* switch de contexte

```
kubectl config use-context Saliou
```

* suppression : utiliser "delete"


