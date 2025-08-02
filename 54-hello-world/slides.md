# HELM : hello world

<br>

* liste des charts

```
helm list --kubeconfig /etc/rancher/k3s/k3s.yaml
```

<br>

```
hello-world /
  Chart.yaml 		# Description Chart
  values.yaml		# Variables (template)
  templates /		# templates de manifests
  charts /			# sous charts (optionnel)
  .helmignore		# ignorer des fichiers pour le dépôt
```

<br>

* création d'un chart

```
helm create hello-Saliou
```

<br>

* lancement

```
helm install --kubeconfig /etc/rancher/k3s/k3s.yaml hello-Saliou ./hello-Saliou/
```

<br>

* suppression

```
helm uninstall --kubeconfig /etc/rancher/k3s/k3s.yaml hello-Saliou ./hello-Saliou/
```


* fichiers joints

