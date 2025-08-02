#!/usr/bin/bash

###############################################################
#  TITRE: add monitoring to the cluster
#
#  AUTEUR:   Xavier
#  VERSION: 
#  CREATION:  
#  MODIFIE: 
#
#  DESCRIPTION: 
###############################################################



# Variables ###################################################

IP_NFS=$(hostname -I | cut -d " " -f2)
URL_PROMETHEUS="${1:-prometheus.kub}"
URL_GRAFANA="${2:-grafana.kub}"
URL_WORDPRESS="${3:-wordpress.kub}"

# Functions ###################################################

install_repos_dir(){

kubectl create ns monitoring
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add kube-state-metrics https://kubernetes.github.io/kube-state-metrics
helm repo update

mkdir -p /home/vagrant/{monitoring,wordpress,istio}
chmod 775 -R /home/vagrant/monitoring
chown -R vagrant /home/vagrant/*

}


istio_configure_svc(){

echo '
apiVersion: v1
kind: Service
metadata:
  annotations:
  labels:
    app: istio-ingressgateway
    install.operator.istio.io/owning-resource: unknown
    install.operator.istio.io/owning-resource-namespace: istio-system
    istio: ingressgateway
    istio.io/rev: default
    operator.istio.io/component: IngressGateways
    operator.istio.io/managed: Reconcile
    operator.istio.io/version: 1.11.4
    release: istio
  name: istio-ingressgateway
  namespace: istio-system
spec:
  externalTrafficPolicy: Cluster
  ports:
  - name: status-port
    nodePort: 31242
    port: 15021
    protocol: TCP
    targetPort: 15021
  - name: http2
    nodePort: 31080
    port: 80
    protocol: TCP
    targetPort: 8080
  - name: https
    nodePort: 31443
    port: 443
    protocol: TCP
    targetPort: 8443
  - name: tcp
    nodePort: 30400
    port: 31400
    protocol: TCP
    targetPort: 31400
  - name: tls
    nodePort: 31543
    port: 15443
    protocol: TCP
    targetPort: 15443
  selector:
    app: istio-ingressgateway
    istio: ingressgateway
  sessionAffinity: None
  type: NodePort
'> /home/vagrant/istio/svc-istio.yaml


}

istio_create_tools(){

curl -sL https://raw.githubusercontent.com/istio/istio/release-1.11/samples/addons/prometheus.yaml -o /home/vagrant/istio/prometheus.yaml
curl -sL https://raw.githubusercontent.com/istio/istio/release-1.11/samples/addons/kiali.yaml -o /home/vagrant/istio/kiali.yaml
curl -sL https://raw.githubusercontent.com/istio/istio/release-1.11/samples/addons/grafana.yaml -o /home/vagrant/istio/grafana.yaml

}

istio_svc_tools(){

echo '
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: istio
  name: kiali
  namespace: istio-system
spec:
  rules:
  - host: kiali.kub
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          serviceName: kiali
          servicePort: 20001
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: istio
  name: grafana
  namespace: istio-system
spec:
  rules:
  - host: grafana-istio.kub
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          serviceName: grafana
          servicePort: 3000
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: istio
  name: prometheus
  namespace: istio-system
spec:
  rules:
  - host: prometheus-istio.kub
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          serviceName: prometheus
          servicePort: 9090
'> /home/vagrant/istio/ingress-tools-istio.yaml

}


wordpress_create_pv(){

echo '
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mysql-pv
spec:
  storageClassName: mysql
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  nfs:
    server: '${IP_NFS}'
    path: "/srv/wordpress/db"
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: wordpress-pv
spec:
  storageClassName: wordpress
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  nfs:
    server: '${IP_NFS}'
    path: "/srv/wordpress/files"
'> /home/vagrant/wordpress/pv.yml

}

wordpress_create_pvc(){

echo '
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: wordpress-wordpress
spec:
  storageClassName: wordpress
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: wordpress-mysql
spec:
  storageClassName: mysql
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
'> /home/vagrant/wordpress/pvc.yml

}

wordpress_create_deployment(){

echo '
apiVersion: v1
kind: Secret
metadata:
  name: mysql-pass
type: Opaque
data:
  password: "bW9ucGFzc3dvcmQ="
---
apiVersion: apps/v1 
kind: Deployment
metadata:
  name: wordpress-mysql
  labels:
    app: wordpress
spec:
  selector:
    matchLabels:
      app: wordpress-mysql
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: wordpress-mysql
    spec:
      containers:
      - image: mysql:5.6
        name: mysql
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-pass
              key: password
        ports:
        - containerPort: 3306
          name: mysql
        volumeMounts:
        - name: mysql-persistent-storage
          mountPath: /var/lib/mysql
      volumes:
      - name: mysql-persistent-storage
        persistentVolumeClaim:
          claimName: wordpress-mysql
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress
  labels:
    app: wordpress
spec:
  selector:
    matchLabels:
      app: wordpress-wordpress
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: wordpress-wordpress
    spec:
      containers:
      - image: wordpress:5.4.1-apache
        name: wordpress
        env:
        - name: WORDPRESS_DB_HOST
          value: wordpress-mysql
        - name: WORDPRESS_DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-pass
              key: password
        ports:
        - containerPort: 80
          name: wordpress
        volumeMounts:
        - name: wordpress-persistent-storage
          mountPath: /var/www/html
      volumes:
      - name: wordpress-persistent-storage
        persistentVolumeClaim:
          claimName: wordpress-wordpress
'> /home/vagrant/wordpress/deployments.yml

}


monitoring_install_persistent_volume_alertmanager(){

echo '
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: alertmanager
  namespace: monitoring
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
' > /home/vagrant/monitoring/sc-alertmanager.yml

echo '
apiVersion: v1
kind: PersistentVolume
metadata:
  name: alertmanager
spec:
  storageClassName: alertmanager
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  nfs:
    server: '${IP_NFS}'
    path: "/srv/monitoring/prometheus/"
' > /home/vagrant/monitoring/pv-alertmanager.yml

}

monitoring_install_persistent_volume_prometheus(){

echo '
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: prometheus
  namespace: monitoring
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
' > /home/vagrant/monitoring/sc-prometheus.yml

echo '
apiVersion: v1
kind: PersistentVolume
metadata:
  name: prometheus
spec:
  storageClassName: prometheus
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  nfs:
    server: '${IP_NFS}'
    path: "/srv/monitoring/prometheus/"
' > /home/vagrant/monitoring/pv-prometheus.yml

}

monitoring_install_helm_release_prometheus(){

echo '
---
apiVersion: helm.fluxcd.io/v1
kind: HelmRelease
metadata:
  name: prometheus
  namespace: monitoring
spec:
  releaseName: kube-prometheus-stack
  chart:
    name: kube-prometheus-stack
    version: 45.7.1
    repository: https://prometheus-community.github.io/helm-charts
  values:
    prometheus:
      enabled: true
      prometheusSpec:
        storageSpec:
          volumeClaimTemplate:
            spec:
              storageClassName: prometheus
              accessModes: ["ReadWriteMany"]
              resources:
                requests:
                  storage: 1Gi
        additionalScrapeConfigs:
          - job_name: kubernetes-pods
            kubernetes_sd_configs:
            - role: pod
            relabel_configs:
            - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
              action: keep
              regex: true
            - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
              action: replace
              target_label: __metrics_path__
              regex: (.+)
            - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
              action: replace
              regex: ([^:]+)(?::\d+)?;(\d+)
              replacement: $1:$2
              target_label: __address__
            - action: labelmap
              regex: __meta_kubernetes_pod_label_(.+)
            - source_labels: [__meta_kubernetes_namespace]
              action: replace
              target_label: kubernetes_namespace
            - source_labels: [__meta_kubernetes_pod_name]
              action: replace
              target_label: kubernetes_pod_name
' > /home/vagrant/monitoring/hr-prometheus.yml

}

monitoring_install_service_ingress_prometheus(){

echo '
kind: Service
apiVersion: v1
metadata:
  name: prometheus
spec:
  type: ExternalName
  externalName: kube-prometheus-stack-prometheus.monitoring.svc.cluster.local
  ports:
  - port: 9090
' > /home/vagrant/monitoring/svc-prometheus.yml

echo '
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: prometheus
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: '${URL_PROMETHEUS}'
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: prometheus
            port:
              number: 9090
' > /home/vagrant/monitoring/ingress-prometheus.yml

}

monitoring_install_service_ingress_grafana(){

echo '
kind: Service
apiVersion: v1
metadata:
  name: grafana
spec:
  type: ExternalName
  externalName: kube-prometheus-stack-grafana.monitoring.svc.cluster.local
  ports:
  - port: 80
' > /home/vagrant/monitoring/svc-grafana.yml

echo '
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: '${URL_GRAFANA}'
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: grafana
            port:
              number: 80
' > /home/vagrant/monitoring/ingress-grafana.yml

}

# Let's Go !! #################################################


install_repos_dir
istio_configure_svc
istio_create_tools
istio_svc_tools
wordpress_create_pv
wordpress_create_pvc
wordpress_create_deployment
monitoring_install_persistent_volume_alertmanager
monitoring_install_persistent_volume_prometheus
monitoring_install_helm_release_prometheus
monitoring_install_service_ingress_prometheus
monitoring_install_service_ingress_grafana
