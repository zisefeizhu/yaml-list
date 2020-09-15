
# Prometheus联邦平台环境部署
环境：aliyun
### 联邦平台拓扑图
![](https://cdn.nlark.com/yuque/0/2020/png/1143489/1600158312535-58d92c7b-f2ce-45dc-9fd1-9ea348bd8e8a.png)
### Prometheus有关资料
github：https://github.com/prometheus

## 名称空间
prometheus-namespace.yaml
```
apiVersion: v1
kind: Namespace
metadata:
  name: mon
```
## 存储
在这里将实现prometheus和grafana的数据持久化存储
使用的存储插件是csi
```
# kubectl get pods -n kube-system | grep csi
csi-plugin-8bbnw                                     9/9     Running     0          21d
csi-plugin-fszg9                                     9/9     Running     0          21d
csi-provisioner-56f7fb5bd5-bdnnr                     8/8     Running     0          21d
csi-provisioner-56f7fb5bd5-r8ttz                     8/8     Running     0          21d
```
将数据存储到aliyun的nas上
![](https://cdn.nlark.com/yuque/0/2020/png/1143489/1600158594745-46da39d8-f340-4b1d-bc47-8b6233c56c1f.png)
有关使用阿里云nas实现静态、动态pv请跳转：https://github.com/zisefeizhu/work-issues/blob/master/在阿里云k8s集群上使用nas做动态存储.md
storageclass.yaml
```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: prometheus-storageclass
  namespace: mon
mountOptions:
- nolock,tcp,noresvport
- vers=3
parameters:
  volumeAs: subpath
  server: "29afc4b600-mju20.cn-shenzhen.nas.aliyuncs.com:/prometheus/"
provisioner: nasplugin.csi.alibabacloud.com
reclaimPolicy: Retain

# kubectl apply -f storageclass.yaml
# kubectl get storageclass  -n mon
NAME                       PROVISIONER                       AGE
alicloud-disk-available    alicloud/disk                     20d
alicloud-disk-efficiency   alicloud/disk                     20d
alicloud-disk-essd         alicloud/disk                     20d
alicloud-disk-ssd          alicloud/disk                     20d
alicloud-disk-topology     diskplugin.csi.alibabacloud.com   21d
prometheus-storageclass    nasplugin.csi.alibabacloud.com    11m
```
prometheus-pvc.yaml
```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: prometheus-pvc
  namespace: mon
spec:
  storageClassName: prometheus-storageclass
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 5Gi
```
grafana-pvc.yaml
```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: grafana-pvc
  namespace: mon
spec:
  storageClassName: prometheus-storageclass
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 5Gi
```
部署pvc
```
# ls
grafana-pvc.yaml        prometheus-pvc.yaml     storageclass.yaml

# kubectl apply -f prometheus-pvc.yaml 
persistentvolumeclaim/prometheus-pvc created
# kubectl apply -f grafana-pvc.yaml 
persistentvolumeclaim/grafana-pvc created

# kubectl get pvc -n mon
NAME             STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS              AGE
grafana-pvc      Bound    nas-18131934-5de3-4487-bae0-d0f74496ad34   5Gi        RWX            prometheus-storageclass   5s
prometheus-pvc   Bound    nas-ee7573e5-8b4a-44b3-83da-c5e1c456a5e0   5Gi        RWX            prometheus-storageclass   15m

# kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                              STORAGECLASS              REASON   AGE
nas-18131934-5de3-4487-bae0-d0f74496ad34   5Gi        RWX            Retain           Bound    mon/grafana-pvc                    prometheus-storageclass            2m24s
nas-ee7573e5-8b4a-44b3-83da-c5e1c456a5e0   5Gi        RWX            Retain           Bound    mon/prometheus-pvc                 prometheus-storageclass            18m
```
至此prometheus的动态pv创建完毕
👌！
## 部署node-exporter
node-exporter-daemonset.yaml
```
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-exporter
  namespace: mon
  labels:
    app: node-exporter
spec:
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: node-exporter
  template:
    metadata:
      labels:
        app: node-exporter
    spec:
      containers:
        - name: node-exporter
          image: prom/node-exporter:v0.16.0
          ports:
            - containerPort: 9100
              protocol: TCP
              name: http
      hostNetwork: true
      hostPID: true

# kubectl apply -f node-exporter.yaml 
daemonset.apps/node-exporter created

# kubectl get pods -n mon
NAME                  READY   STATUS    RESTARTS   AGE
node-exporter-dg2z5   1/1     Running   0          51s
node-exporter-xzd9j   1/1     Running   0          51s
```
node-exporter-svc.yaml
```
apiVersion: v1
kind: Service
metadata:
  name: node-exporter-service
  namespace: mon
  labels:
    app: node-exporter-service
spec:
  ports:
    - name: http
      port: 9100
      nodePort: 31672
      protocol: TCP
  type: NodePort
  selector:
    app: node-exporter

# kubectl apply -f node-exporter-svc.yaml 
service/node-exporter-service created
# kubectl get svc -n mon
NAME                    TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
node-exporter-service   NodePort   10.0.195.117   <none>        9100:31672/TCP   15s

因为k8s节点是在内网，无法访问到，使用跳板机访问
# ssh gitlab
# curl -i 172.16.0.122:31672/metrics > metrics.txt
# head -19 metrics.txt 
HTTP/1.1 200 OK
Content-Length: 114028
Content-Type: text/plain; version=0.0.4; charset=utf-8
Date: Tue, 15 Sep 2020 10:04:43 GMT

# HELP go_gc_duration_seconds A summary of the GC invocation durations.
# TYPE go_gc_duration_seconds summary
go_gc_duration_seconds{quantile="0"} 6.0118e-05
go_gc_duration_seconds{quantile="0.25"} 6.0118e-05
go_gc_duration_seconds{quantile="0.5"} 9.433e-05
go_gc_duration_seconds{quantile="0.75"} 0.000211111
go_gc_duration_seconds{quantile="1"} 0.000211111
go_gc_duration_seconds_sum 0.000365559
go_gc_duration_seconds_count 3
# HELP go_goroutines Number of goroutines that currently exist.
# TYPE go_goroutines gauge
go_goroutines 7
# HELP go_info Information about the Go environment.
# TYPE go_info gauge
```
至此，node-exporter部署完成并运行成功👌！
## 部署Prometheus
prometheus-rbac.yaml
```
apiVersion: rbac.authorization.k8s.io/v1 # api的version
kind: ClusterRole # 类型
metadata:
  name: prometheus
rules:
- apiGroups: [""]
  resources: # 资源
  - nodes
  - nodes/proxy
  - services
  - endpoints
  - pods
  verbs: ["get", "list", "watch"] 
- apiGroups:
  - extensions
  resources:
  - ingresses
  verbs: ["get", "list", "watch"]
- nonResourceURLs: ["/metrics"]
  verbs: ["get"]
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus # 自定义名字
  namespace: mon # 命名空间
  labels:
    app: prometheus
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: prometheus
roleRef: # 选择需要绑定的Role
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: prometheus
subjects: # 对象
- kind: ServiceAccount
  name: prometheus
  namespace: mon

# kubectl apply -f prometheus-rbac.yaml 
clusterrole.rbac.authorization.k8s.io/prometheus created
serviceaccount/prometheus created
clusterrolebinding.rbac.authorization.k8s.io/prometheus created
```
prometheus-configmap.yaml
```
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-conf
  namespace: mon
  labels:
    app: prometheus
data:
  prometheus.yml: |-
    # my global config
    global:
      scrape_interval:     15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
      evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
      # scrape_timeout is set to the global default (10s).
 
    # Alertmanager configuration
    alerting:
      alertmanagers:
      - static_configs:
        - targets:
            - 'alertmanager-service.mon:9093'    #如果报错，可以先注释此行，后续会添加此配置
    # Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
    rule_files:
      - "/etc/prometheus/rules/nodedown.rule.yml"
    scrape_configs:
      - job_name: 'prometheus'
        static_configs:
          - targets: ['localhost:9090']
      - job_name: 'grafana'
        static_configs:
          - targets:
              - 'grafana-service.mon:3000'
 
      - job_name: 'kubernetes-apiservers'
 
        kubernetes_sd_configs:
        - role: endpoints
        scheme: https
        tls_config:
          ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
        relabel_configs:
        - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
          action: keep
          regex: default;kubernetes;https
 
      - job_name: 'kubernetes-nodes'
 
        scheme: https
        tls_config:
          ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
 
        kubernetes_sd_configs:
        - role: node
 
        relabel_configs:
        - action: labelmap
          regex: __meta_kubernetes_node_label_(.+)
        - target_label: __address__
          replacement: kubernetes.default.svc:443
        - source_labels: [__meta_kubernetes_node_name]
          regex: (.+)
          target_label: __metrics_path__
          replacement: /api/v1/nodes/${1}/proxy/metrics
 
      - job_name: 'kubernetes-cadvisor'
        scheme: https
        tls_config:
          ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
 
        kubernetes_sd_configs:
        - role: node
 
        relabel_configs:
        - action: labelmap
          regex: __meta_kubernetes_node_label_(.+)
        - target_label: __address__
          replacement: kubernetes.default.svc:443
        - source_labels: [__meta_kubernetes_node_name]
          regex: (.+)
          target_label: __metrics_path__
          replacement: /api/v1/nodes/${1}/proxy/metrics/cadvisor
 
      - job_name: 'kubernetes-service-endpoints'
 
        kubernetes_sd_configs:
        - role: endpoints
 
        relabel_configs:
        - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
          action: keep
          regex: true
        - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scheme]
          action: replace
          target_label: __scheme__
          regex: (https?)
        - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
          action: replace
          target_label: __metrics_path__
          regex: (.+)
        - source_labels: [__address__, __meta_kubernetes_service_annotation_prometheus_io_port]
          action: replace
          target_label: __address__
          regex: ([^:]+)(?::\d+)?;(\d+)
          replacement: $1:$2
        - action: labelmap
          regex: __meta_kubernetes_service_label_(.+)
        - source_labels: [__meta_kubernetes_namespace]
          action: replace
          target_label: kubernetes_namespace
        - source_labels: [__meta_kubernetes_service_name]
          action: replace
          target_label: kubernetes_name
 
      - job_name: 'kubernetes-services'
 
        metrics_path: /probe
        params:
          module: [http_2xx]
 
        kubernetes_sd_configs:
        - role: service
 
        relabel_configs:
        - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_probe]
          action: keep
          regex: true
        - source_labels: [__address__]
          target_label: __param_target
        - target_label: __address__
          replacement: blackbox-exporter.example.com:9115
        - source_labels: [__param_target]
          target_label: instance
        - action: labelmap
          regex: __meta_kubernetes_service_label_(.+)
        - source_labels: [__meta_kubernetes_namespace]
          target_label: kubernetes_namespace
        - source_labels: [__meta_kubernetes_service_name]
          target_label: kubernetes_name
 
      - job_name: 'kubernetes-ingresses'
 
        metrics_path: /probe
        params:
          module: [http_2xx]
 
        kubernetes_sd_configs:
          - role: ingress
 
        relabel_configs:
          - source_labels: [__meta_kubernetes_ingress_annotation_prometheus_io_probe]
            action: keep
            regex: true
          - source_labels: [__meta_kubernetes_ingress_scheme,__address__,__meta_kubernetes_ingress_path]
            regex: (.+);(.+);(.+)
            replacement: ${1}://${2}${3}
            target_label: __param_target
          - target_label: __address__
            replacement: blackbox-exporter.example.com:9115
          - source_labels: [__param_target]
            target_label: instance
          - action: labelmap
            regex: __meta_kubernetes_ingress_label_(.+)
          - source_labels: [__meta_kubernetes_namespace]
            target_label: kubernetes_namespace
          - source_labels: [__meta_kubernetes_ingress_name]
            target_label: kubernetes_name
 
      - job_name: 'kubernetes-pods'
 
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

# kubectl apply -f prometheus-configmap.yaml 
configmap/prometheus-configmap created
```
prometheus-rules.yaml
```
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-rules
  namespace: mon
  labels:
    app: prometheus
data:
  nodedown.rule.yml: |
    groups:
    - name: test-rule
      rules:
      - alert: NodeDown
        expr: up == 0
        for: 1m
        labels:
          team: node
        annotations:
          summary: "{{$labels.instance}}: down detected"
          description: "{{$labels.instance}}:  is down 1m (current value is: {{ $value }}"

# kubectl apply -f prometheus-rules.yaml 
configmap/prometheus-rules created
```
prometheus-deployment.yaml
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: mon
  labels:
    app: prometheus
spec:
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      serviceAccountName: prometheus
      securityContext:
        runAsUser: 0
      containers:
        - name: prometheus
          image: prom/prometheus:latest
          volumeMounts:
            - mountPath: /prometheus
              name: prometheus-data-volume
            - mountPath: /etc/prometheus/prometheus.yml
              name: prometheus-conf-volume
              subPath: prometheus.yml
            - mountPath: /etc/prometheus/rules
              name: prometheus-rules-volume
          ports:
            - containerPort: 9090
              protocol: TCP
      volumes:
        - name: prometheus-data-volume
          persistentVolumeClaim:
            claimName: prometheus-pvc
        - name: prometheus-conf-volume
          configMap:
            name: prometheus-conf
        - name: prometheus-rules-volume
          configMap:
            name: prometheus-rules

# kubectl apply -f prometheus-deployment.yaml 
deployment.apps/prometheus created
# kubectl get pods -n mon -w
NAME                         READY   STATUS              RESTARTS   AGE
node-exporter-dg2z5          1/1     Running             0          27m
node-exporter-xzd9j          1/1     Running             0          27m
prometheus-f4d9d9ff7-dvb7q   0/1     ContainerCreating   0          8s
prometheus-f4d9d9ff7-dvb7q   1/1     Running             0          21s
```
prometheus-svc.yaml
```
apiVersion: v1
kind: Service
metadata:
  annotations:
    prometheus.io/scrape: 'true'
  labels:
    app: prometheus
  name: prometheus-service
  namespace: mon
spec:
  ports:
    - port: 9090
      targetPort: 9090
  selector:
    app: prometheus
  type: ClusterIP

# kubectl apply -f prometheus-svc.yaml 
service/prometheus-service created
# kubectl get svc -n mon
NAME                    TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
prometheus-service      ClusterIP   10.0.60.238    <none>        9090/TCP         5s
```
prometheus-ingress.yaml
```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: prometheus-ingress
  namespace: mon
  annotations:
    kubernets.io/ingress.class: "kong"
spec:
  tls:
  - hosts:
    - "*.realibox.cn"        #与secret证书的域名需要保持一致
    secretName: realibox-cn   #secret证书的名称
  rules:
  - host: prometheus.realibox.cn
    http:
      paths:
      - path:
        backend:
          serviceName: prometheus-service
          servicePort: 9090

# kubectl apply -f prometheus-ingress.yaml 
ingress.extensions/prometheus-ingress created
# kubectl get ingress -n mon
NAME                 HOSTS                    ADDRESS         PORTS     AGE
prometheus-ingress   prometheus.realibox.cn   47.112.190.16   80, 443   8s
```
浏览器访问
![](https://cdn.nlark.com/yuque/0/2020/png/1143489/1600165793945-48a405c8-c442-4428-8afa-4e594b488303.png)
至此，prometheus部署完毕👌！
## 部署grafana
grafana-deployment.yaml
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
  namespace: mon
  labels:
    app: grafana
spec:
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      securityContext:
        runAsUser: 0
      containers:
        - name: grafana
          image: grafana/grafana:latest
          env:
            - name: GF_AUTH_BASIC_ENABLED
              value: "true"
            - name: GF_AUTH_ANONYMOUS_ENABLED
              value: "false"
          readinessProbe:
            httpGet:
              path: /login
              port: 3000
          volumeMounts:
            - mountPath: /var/lib/grafana
              name: grafana-data-volume
          ports:
            - containerPort: 3000
              protocol: TCP
      volumes:
        - name: grafana-data-volume
          persistentVolumeClaim:
            claimName: grafana-pvc

# kubectl apply -f grafana-deployment.yaml 
deployment.apps/grafana created
zisefeizhu:grafanan root# kubectl get pods -n mon -w
NAME                         READY   STATUS              RESTARTS   AGE
grafana-6995d876cc-8q8hm     0/1     ContainerCreating   0          6s
node-exporter-dg2z5          1/1     Running             0          43m
node-exporter-xzd9j          1/1     Running             0          43m
prometheus-f4d9d9ff7-dvb7q   1/1     Running             0          16m
grafana-6995d876cc-8q8hm     0/1     Running             0          28s
grafana-6995d876cc-8q8hm     1/1     Running             0          45s
```
grafana-svc.yaml
```
apiVersion: v1
kind: Service
metadata:
  labels:
    app: grafana
  name: grafana-service
  namespace: mon
spec:
  ports:
    - port: 3000
      targetPort: 3000
  selector:
    app: grafana
  type: ClusterIP

# kubectl apply -f grafana-svc.yaml 
service/grafana-service created
# kubectl get svc -n mon
NAME                    TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
grafana-service         ClusterIP   10.0.220.24    <none>        3000/TCP         7s
```
grafana-ingress.yaml
```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: grafana-ingress
  namespace: mon
  annotations:
    kubernets.io/ingress.class: "kong"
spec:
  tls:
  - hosts:
    - "*.realibox.cn"        #与secret证书的域名需要保持一致
    secretName: realibox-cn   #secret证书的名称
  rules:
  - host: grafana.realibox.cn
    http:
      paths:
      - path:
        backend:
          serviceName: grafana-service
          servicePort: 3000

# kubectl apply -f grafana-ingress.yaml 
ingress.extensions/grafana-ingress created
# kubectl get ingress -n mon
NAME                 HOSTS                    ADDRESS         PORTS     AGE
grafana-ingress      grafana.realibox.cn      47.112.190.16   80, 443   34s
```
浏览器访问
![](https://cdn.nlark.com/yuque/0/2020/png/1143489/1600166896884-3a09c0c8-639b-4ff8-b877-ce18c0dbca27.png)
至此，grafana部署完毕👌！







