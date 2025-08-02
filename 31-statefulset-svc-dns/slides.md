# StatefulSet - Service Headless


<br>

* création de service headless pour dns interne qui résoud tous les pods

* utiles pour les BDD distribuées qui incluent un round robin / LB interne

* On garde les PersistentVolume qu'on a déja crée


```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv0 # à modifier
spec:
  storageClassName: manual
  capacity:
    storage: 100Mi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/pvdata0" # à modifier
---
```


-----------------------------------------------------------------------

# StatefulSet

```
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: monstatefulset
spec:
  serviceName: svc-dns   # Utilisation du Service Headless à travers son nom
  replicas: 5
  selector:
    matchLabels:
      app: monsts
  template:
    metadata:
      labels:
        app: monsts
    spec:
      containers:
      - name: nginx
        image: nginx
        volumeMounts:
        - name: www
          mountPath: /var/www/html
  volumeClaimTemplates:
  - metadata:
      name: www
    spec:
      storageClassName: manual
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 100Mi
```

-----------------------------------------------------------------------

# Service Headless : none

```
apiVersion: v1
kind: Service
metadata:
  name: svc-dns
  labels:
    app: monginx
spec:
  ports:
  - port: 80      # communication à travers le port 80 
    name: web
  clusterIP: None # On expose pas le Service, on a une communication en interne	entre les pods: permet de qualifier le service Headless
  selector:
    app: monsts   # important pour la sélection des pods entrant dans le dns
```


-------------------------------------------------------------------------

# Test

```
kubectl exec -ti monstatefulset-0 -- /bin/bash
apt-get update && apt-get install -y dnsutils curl
nslookup svc-dns                                                    # donne les IP des Pods et leur résolution de nom
curl svc-dns.default.svc.cluster.local                              # nom du dns
curl curl monstatefulset-0.svc-dns.default.svc.cluster.local        # Utilsé de dns pour aller sur le pod curl monstatefulset-0
```
