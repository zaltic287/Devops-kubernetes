%title: Kubernetes 

# ReplicaSet : HPA


<br>

* HPA : Horizontal Pods Autoscallers: ajouter d'autres Pods pour répondre à la charge

<br>

* opposition avec VPA (Vertical): Ajouter des ressources supplimentaires aux Podes déja existants

* complémentaires avec CA (Cluster Autoscaller): Instances de nouvelles machines pour répondre aux charges du cluster généralement dans le cloud

<br>

* multiplier le nombre de pods en fonction des ressources
		- min et max
		- seuil de déclenchement

<br>

* à éviter plutôt deployement


<br>

* ressource : 

```
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
```

<br>


pod > replicaset > HPA > deploy


-------------------------------------------------------------------------


# La collecte des métriques


* pas de HPA sans métriques

<br>

* installation de metrics-server :
		- collecte de métriques pourles fournir par API (kubelet)
		- CPU ou mémoire notamment

<br>

0- agregation layer

```
https://kubernetes.io/docs/tasks/access-kubernetes-api/configure-aggregation-layer/
```

Rq : sauf si installation kubespray

<br>

1- clone de metrics-server

```
git clone https://github.com/kubernetes-incubator/metrics-server.git

cd metrics-server

cd deploy

ls

vim metrics-server-deployement.yaml
```

<br>

2- sans tls

```
      - name: metrics-server
        image: k8s.gcr.io/metrics-server-amd64:v0.3.3
        command:
        - /metrics-server
        - --kubelet-insecure-tls
        - --kubelet-preferred-address-types=InternalIP
```

<br>

3- vérification

```
kubectl top nodes
```


-------------------------------------------------------------------------

# Création d'un déploiement


```
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: monfront
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: monfront
    spec:
      containers:
      - name: monpod
        image: httpd
        resources:
          requests:
            cpu: 10m
```


------------------------------------------------------------------------

# Squelette du HPA


<br>

```
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
  name: monhpa
spec:
  scaleTargetRef:
    apiVersion: extensions/v1beta1
    kind: Deployment
    name: monfront
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 11
  
```

* CLI

```
kubectl autoscale rs frontend --max=10
```

* service

```
kubectl create service nodeport monfront --tcp=8080:80
```

