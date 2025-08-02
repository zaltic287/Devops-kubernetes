# RBAC : Service Account et Rôles


<br>

3 ressources importantes et combinées :

* cluster role : un rôle est un profil permettant des accès/actions/ressources

* service account : user applicatif

* cluster role binding : association d'un service account à un rôle

------------------------------------------------------------------------


# Cluster Role



```
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: cr1
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list", "watch", "patch"]
- apiGroups: [""] 
  resources: ["pods"]
  verbs: ["describe"]
```


--------------------------------------------------------------------------


# Service account

```
apiVersion: v1
kind: ServiceAccount
metadata:
 name: Saliou
```

# Cluster Role Binding

```
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: Saliou
subjects:
- kind: ServiceAccount
  name: Saliou
  namespace: default
roleRef:
  kind: ClusterRole
  name: cr1
  apiGroup: rbac.authorization.k8s.io
```

--------------------------------------------------------------------------


# Récupération du token


<br>

* récupération du token

```
kubectl get sa Saliou -o yaml
```

<br>

* visualisation du secrets

```
kubectl get secrets Saliou-token-g2gqt
```

---------------------------------------------------------------------------

# Pods de test


```
apiVersion: v1
kind: Pod
metadata:
  name: pod-default
  namespace: default
spec:
  serviceAccountName: Saliou
  containers:
  - image: alpine:3.9
    name: alpine
    command:
    - sleep
    - "10000"
    volumeMounts:
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: Saliou-token-g2gqt
  volumes:
  - name: Saliou-token-g2gqt
    secret:
      secretName: Saliou-token-g2gqt
```

---------------------------------------------------------------------------

# Test


```
kubectl exec -ti pod-default -- sh
apk add --update curl
TOKEN=$(cat /run/secrets/kubernetes.io/serviceaccount/token)
curl -H "Authorization: Bearer $TOKEN" https://kubernetes/api/v1/ --insecure
curl -H "Authorization: Bearer $TOKEN" https://kubernetes/api/v1/services --insecure
curl -H "Authorization: Bearer $TOKEN" https://kubernetes/api/v1/pods --insecure
```

---------------------------------------------------------------------


TOKENNAME=`kubectl -n kube-system get serviceaccount/admin -o jsonpath='{.secrets[0].name}'`
TOKEN=`kubectl -n kube-system get secret $TOKENNAME -o jsonpath='{.data.token}' | base64 -d`
kubectl config set-credentials admin --token=$TOKEN
kubectl config set-context admin@kubernetes --cluster kubernetes --user admin
