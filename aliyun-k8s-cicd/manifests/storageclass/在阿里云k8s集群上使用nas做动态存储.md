### 前言

关于aliyun托管k8s的存储插件主要有两种：

#### CSI

```
# kubectl get pod -n kube-system | grep csi-plugin
csi-plugin-8bbnw                                     9/9     Running     0          26h
csi-plugin-fszg9                                     9/9     Running     0          26h
```

#### flexvolume

```
#  kubectl get pod -n kube-system | grep flexvolume
flexvolume-5fw55                                   1/1     Running            4          288d
flexvolume-992jr                                   1/1     Running            3          288d
flexvolume-f8thl                                   1/1     Running            15         320d
flexvolume-jfzhc                                   1/1     Running            0          6d3h
flexvolume-zjm67                                   1/1     Running            3          152d
```

#### 插件对比及介绍

详细请看：https://help.aliyun.com/document_detail/157026.html?spm=a2c4g.11186623.6.787.18e320dbvg3zQT

### 两种插件的使用

#### CSI

https://help.aliyun.com/document_detail/144398.html

注意：NAS的挂载点要和K8S集群在同一专有网络下

#### flexvolume

https://www.yuque.com/docs/share/dcb99888-a491-4802-b321-184bf482f672?# 《在kubernetes集群动态使用nas持久卷》

这篇文章要详细的使用案例

### 注意

在为阿里云k8s做存储前一定要看清楚使用的是那种存储插件，不然会出现一下问题：

pod一直处于ContainerCreating   describe查看是因为挂载失败了，大致如下：  Warning  FailedMount  6m19s (x2 over 13m)  kubelet, cn-shenzhen.172.16.0.123  Unable to attach or mount volumes: unmounted volumes=[alicloud-nas], unattached volumes=[default-token-tk4g4 alicloud-nas]: timed out waiting for the condition 

![image.png](https://cdn.nlark.com/yuque/0/2020/png/1143489/1598419253540-6af4b2ef-6899-4a77-9ac1-efad79e5a18e.png)