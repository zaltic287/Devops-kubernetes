# StatefulSet


<br>

* déploiement des applications stateful (bases de données par ex)

<br>

* particularité :
		- ordonnées (dans le lancement)
		- garde en mémoire les volumes attachés

<br>

* création de service headless pour dns interne (chaque pods à un dns)

-----------------------------------------------------------------------

# Création des Persistent Volumes

```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv0
spec:
  storageClassName: manual
  capacity:
    storage: 100Mi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /pvdata1
---

apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv1
spec:
  storageClassName: manual
  capacity:
    storage: 100Mi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /pvdata2  
	
---

apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv2
spec:
  storageClassName: manual
  capacity:
    storage: 100Mi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /pvdata3  
	
---

apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv3
spec:
  storageClassName: manual
  capacity:
    storage: 100Mi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /pvdata4  

---

apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv4
spec:
  storageClassName: manual
  capacity:
    storage: 100Mi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /pvdata5 
	
---
* creer un index.html sur chaque volume

kubectl apply -f pv.yml
```

* Attention : sans stockage distribué créer pour la démo un répertoire/fichier sur chaque noeud
* les repertoires /pvdata sont crées sur l'ensemble des noeuds

------------------------------------------------------------------------
```
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: monstatefulset
spec:
  serviceName: dns-sts
  replicas: 4
  selector:
    matchLabels:
      app: monsts
  template:           # Définition d'un template de pods
    metadata:
      labels:
        app: monsts
    spec:
      containers:
      - name: nginx
        image: nginx
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:                    # Défintion d'un PersistentVolumeClaim directement qui sera attaché aux Pods
  - metadata:
      name: www
    spec:
      storageClassName: manual             # Fait le lien avec les volumes Persistents qu'on a crée
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 100Mi
```

*kubectl apply -f nginx-stateful.yml
*kubectl get sts
*kubectl get pods

* Si je supprime un Pod, il sera recrée et sera toujours rattaché au volume auquel il a été rattaché avant sa suppression 

