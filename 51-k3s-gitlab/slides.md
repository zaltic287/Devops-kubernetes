# K3S & GITLAB CI


<br>

* créer un projet gitlab
* allez dans operation>> kubernetes
* add kubernetes cluster
* donner l@ip de l'api server

<br>

* intégration du cluster dans gitlab

<br>

* récupération de l@ip:6443 du master et le coller dans l' API url dans gitlab

* récupération du certificat et coller dans gitlab

```
kubectl config view --raw -o=jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 --decode
```

-----------------------------------------------------------------------------


# K3S & GITLAB CI


<br>

* rbac gitlab: un profil qui définit ce qu'on peut faire avec les ressources du cluster

vim rbac.yml
kubectl apply -f rbac.yml

```
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: gitlab-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: gitlab-admin
  namespace: kube-system
```

<br>

* récupération du token

```
SECRET=$(kubectl -n kube-system get secret | grep gitlab-admin | awk '{print $1}')
TOKEN=$(kubectl -n kube-system get secret $SECRET -o jsonpath='{.data.token}' | base64 --decode)
echo $TOKEN
```

-----------------------------------------------------------------------------


# K3S & GITLAB CI


<br>

* installation du runner dans gitlab

<br>

<br>

* installation de git en local
* commit de .gitlab-ci.yml

<br>

* test

git init
git add remote
git add .
git commit -m ""
git push -u origin master

```
stages:
- deploy

variables:
  MESSAGE: "Hello World."

app-deploy:
  stage: deploy
  tags:
      - kubernetes
  environment:
    name: deploy
  script:
    - echo $MESSAGE
  only:
    - master
```
