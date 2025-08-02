# ConfigMaps et Secrets : utilisation


<br>


* création par la ligne de commande - CLI

<br>


* possibilité de créer par manifeste


<br>


```
kind: ConfigMap 
apiVersion: v1 
metadata:
  name: personne
data:
  nom: Xavier                        # variable nom qui contient Xavier(key/value)
  passion: blogging                  # variable passion qui contient blogging   
  clef: |                            # Contient un bloc de variable
 
    age.key=40 
    taille.key=180
```

<br>

* 2 types de cas d'Utilisations :
		- volumes
		- configMapKeyRef


-----------------------------------------------------------------

# Utilisations : en variables


<br>


* variables env : configMapKeyRef

<br>


* une à une :

```
apiVersion: v1
kind: Pod
metadata:
  name: monpod
spec:
  containers:
    - name: test-container
      image: k8s.gcr.io/busybox
      command: [ "/bin/sh", "-c", "env" ]
      env:
        - name: NOM
          valueFrom:
            configMapKeyRef:
              name: personne
              key: nom
        - name: PASSION
          valueFrom:
            configMapKeyRef:
              name: personne
              key: passion
```

-------------------------------------------------------------------

# Utilisations : configMapKeyRef


<br>


* toute la configmap entiere contient des variables d'environnement

```
apiVersion: v1
kind: Pod
metadata:
  name: monpod
spec:
  containers:
    - name: test-container
      image: busybox
      command: [ "/bin/sh", "-c", "env" ]
      envFrom:
        - configMapRef:
            name: personne
```

-------------------------------------------------------------------

# ConfigMaps et Secrets : en volumes


<br>

* fichiers ou répertoires


<br>

vim maconf.yaml
```
kind: ConfigMap
apiVersion: v1
metadata:
  name: personne
data:
  clef: |
    Bonjour
    les
    Xavkistes !!!
```
kubectl apply -f maconf.yaml

-------------------------------------------------------------------------------------------------------

# ConfigMaps et Secrets : utilisation dans un pod


<br>


* fichier monté en volume || Le fichier index.htm sera crée par Kubernetes et va mettre dedans le contenu de la key clef qui se trouve
dans la configuration personne

```
apiVersion: v1
kind: Pod
metadata:
  name: monpod
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
    volumeMounts:
    - mountPath: /usr/share/nginx/html/
      name: monvolumeconfig
  volumes:
  - name: monvolumeconfig
    configMap:
      name: personne
      items:
      - key: clef
        path: index.html
```

<br>

Recupere l'adresse IP du Pod au sein du cluster

* kubectl get pods -o wide  
* curl @Ip_du_Pod 
-------------------------------------------------------------------------------------------------------

# ConfigMaps et Secrets : répertoire


<br>


* création

```
kubectl create configmap mondir --from-file=index.html --from-file=monfichier.html
```

* pod

```
apiVersion: v1
kind: Pod
metadata:
  name: monpod
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
    volumeMounts:
    - mountPath: /usr/share/nginx/html/
      name: mondir
  volumes:
  - name: mondir
    configMap:
      name: mondir
```

* curl @Ip_du_Pod 
* curl @Ip_du_Pod/monfichier.html