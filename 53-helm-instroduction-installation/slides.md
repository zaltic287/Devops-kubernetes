# HELM : encore un dépot ??


<br>

* Pourquoi faire ?
	* gestionnaire de "paquets" dédié à K8S
	* simplifier la génération des manifests yaml
	* versionning : updates/rollback
	* charts : stack de fichiers manifests
	* hub helm : https://hub.helm.sh/


* attention évolution V2 > V3
	* suppression de tiller (client/server)
	* commandes renommage (fetch > pull, delete > uninstall, inspect > show)
	* requirements.yaml > Chart.yaml

<br>

* installation :

```
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 755 get_helm.sh 
./get_helm.sh
```

-------------------------------------------------------------------------

# HELM : commandes

<br>

* lister les repository :

```
helm repo list
```

<br>

* rechercher un charts:

```
helm search hub wordpress		# cherche des charts sur le hub
helm search repo wordpress	# cherche des dépôts avec mots clefs dans charts
```

<br>

* helm hub :

```
https://hub.helm.sh/
https://hub.helm.sh/charts/bitnami/wordpress
```

-----------------------------------------------------------------------

# HELM : structure


<br>

helm create --kubeconfig /etc/rancher/k3s/k3s.yaml hello-saliou                    #il cree un repertoire hello-saliou
cd hello-saliou
tree

```
hello-saliou /
  Chart.yaml 		# Description Chart
  values.yaml		# Variables (template)
  templates /		# templates de manifests
  charts /			# sous charts (optionnel)
  .helmignore		# ignorer des fichiers pour le dépôt
```
ensuite il faut aller modifier la Chart (qui comprent les manifests dans les templates)

helm install --kubeconfig /etc/rancher/k3s/k3s.yaml hello-saliou ./hello-saliou



