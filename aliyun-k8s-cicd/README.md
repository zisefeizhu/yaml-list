# 我所看到的集群重构的有关步骤
1、有关服务做拆分

2、拆分后的服务容器化

3、拆分后的服务单独k8s化

4、代码分支作用确定

5、域名规范整合

6、CI/CD重构

7、将3步骤做CI/CD配置清单

8、准备新的测试k8s环境【数据库什么的都是新的】

9、将7步骤部署到8步骤【结合4、6、7步骤实现分支merge即部署】

10、测试8步骤环境服务

11、将7步骤服务部署到生产k8s环境的test namespace【如果原来有生产K8s环境的话，没有就直接搞一个新集群【数据库什么的完全模拟生产环境】】

12、测试11步骤环境服务

13、将7步骤部署到生产k8s的正式namespace 【数据库什么的都是用生产的】

14、测试正式namespace 

15、总结
# 集群重构之CI/CD重构
date: 2020-09-26

by: zisefeizhu[林坤]
## ci/cd是什么？如何理解持续集成、持续交付和持续部署
CI/CD是一种通过在应用开发阶段引入自动化来频繁向客户交付应用的方法。CI/CD的核心概念是持续集成、持续交付和持续部署。作为一个面向开发和运营团队的解决方案，CI/CD主要针对在集成新代码时所引发的问题（亦称：“集成地狱”）。
具体而言，CI/CD可让持续自动化和持续监控贯穿于应用的整个生命周期（从集成和测试阶段，到交付和部署）。这些关联的事务通常被统称为“CI/CD 管道”，由开发和运维团队以敏捷方式协同支持。

### CI 是什么？CI 和 CD 有什么区别？
缩略词CI/CD具有几个不同的含义。CI/CD中的“CI”始终指持续集成，它属于开发人员的自动化流程。成功的 CI 意味着应用代码的新更改会定期构建、测试并合并到共享存储库中。该解决方案可以解决在一次开发中有太多应用分支，从而导致相互冲突的问题。

CI/CD 中的“CD”指的是持续交付和/或持续部署，这些相关概念有时会交叉使用。两者都事关管道后续阶段的自动化，但它们有时也会单独使用，用于说明自动化程度。

持续交付通常是指开发人员对应用的更改会自动进行错误测试并上传到存储库（如GitHub或容器注册表），然后由运维团队将其部署到实时生产环境中。这旨在解决开发和运维团队之间可见性及沟通较差的问题。因此，持续交付的目的就是确保尽可能减少部署新代码时所需的工作量。

持续部署（另一种“CD”）指的是自动将开发人员的更改从存储库发布到生产环境，以供客户使用。它主要为了解决因手动流程降低应用交付速度，从而使运维团队超负荷的问题。持续部署以持续交付的优势为根基，实现了管道后续阶段的自动化。

### CI/CD 流程
CI/CD 既可能仅指持续集成和持续交付构成的关联环节，也可以指持续集成、持续交付和持续部署这三项构成的关联环节。更为复杂的是，有时“持续交付”也包含了持续部署流程。

归根结底，没必要纠结于这些语义，只需记得CI/CD其实就是一个流程（通常形象地表述为管道），用于实现应用开发中的高度持续自动化和持续监控。因案例而异，该术语的具体含义取决于CI/CD管道的自动化程度。许多企业最开始先添加CI，然后逐步实现交付和部署的自动化（例如作为云原生应用的一部分）。
### CI 持续集成（Continuous Integration）

现代应用开发的目标是让多位开发人员同时处理同一应用的不同功能。但是，如果企业安排在一天内将所有分支源代码合并在一起（称为“合并日”），最终可能造成工作繁琐、耗时，而且需要手动完成。这是因为当一位独立工作的开发人员对应用进行更改时，有可能会与其他开发人员同时进行的更改发生冲突。如果每个开发人员都自定义自己的本地集成开发环境（IDE），而不是让团队就一个基于云的IDE达成一致，那么就会让问题更加雪上加霜。

持续集成（CI）可以帮助开发人员更加频繁地（有时甚至每天）将代码更改合并到共享分支或“主干”中。一旦开发人员对应用所做的更改被合并，系统就会通过自动构建应用并运行不同级别的自动化测试（通常是单元测试和集成测试）来验证这些更改，确保这些更改没有对应用造成破坏。这意味着测试内容涵盖了从类和函数到构成整个应用的不同模块。如果自动化测试发现新代码和现有代码之间存在冲突，CI 可以更加轻松地快速修复这些错误。

### 进一步了解技术细节

#### CD 持续交付（Continuous Delivery）
完成CI中构建及单元测试和集成测试的自动化流程后，持续交付可自动将已验证的代码发布到存储库。为了实现高效的持续交付流程，务必要确保CI已内置于开发管道。持续交付的目标是拥有一个可随时部署到生产环境的代码库。

在持续交付中，每个阶段（从代码更改的合并，到生产就绪型构建版本的交付）都涉及测试自动化和代码发布自动化。在流程结束时，运维团队可以快速、轻松地将应用部署到生产环境中。
### CD 持续部署（Continuous Deployment）
对于一个成熟的 CI/CD 管道来说，最后的阶段是持续部署。作为持续交付（自动将生产就绪型构建版本发布到代码存储库）的延伸，持续部署可以自动将应用发布到生产环境。由于在生产之前的管道阶段没有手动门控，因此持续部署在很大程度上都得依赖精心设计的测试自动化。

实际上，持续部署意味着开发人员对应用的更改在编写后的几分钟内就能生效（假设它通过了自动化测试）。这更加便于持续接收和整合用户反馈。总而言之，所有这些 CI/CD 的关联步骤都有助于降低应用的部署风险，因此更便于以小件的方式（而非一次性）发布对应用的更改。不过，由于还需要编写自动化测试以适应 CI/CD 管道中的各种测试和发布阶段，因此前期投资还是会很大。
####简单的讲ci｜cd
##### 什么是CI
持续集成(Continuous integration)频繁的将代码提交然后集成到主干。
##### 什么是CD
持续交付（Continuous Delivery)是在CI的基础上，将集成到主干的代码、产出的可部署软件版本，部署到类生产环境进行测试验证，确认无问题后，再手动部署到生产环境。
![](https://cdn.nlark.com/yuque/0/2020/png/1143489/1601088404832-0a85d4d4-3478-4fc9-ba88-c37a399903b1.png)
👌！至此ci/cd是什么？如何理解持续集成、持续交付和持续部署 阐述完毕！

## 容器平台下的CI|CD工具如何选型
在当前DevOps的趋势下，持续集成（CI）和持续部署（CD）具有支柱性地位，那么，我们为什么要做CI/CD?
CI/CD可以提高效率，减少人工操作。能够快速确定新代码和原有代码能否集成，降低部署风险，快速发现错误。 促使加速软件发布周期。
### Gitlab-ci
GitLab CI / CD是GitLab的一部分,gitlab 8.0版本开始新增的功能，是用Ruby和Go语言编写的。根我们通常的CI系统不一样通常的是一个master-slave架构，即使没有slave，master一样可以做CI，slave只是做为一个压力分担功能，gitlab是gitlab-server本身是不执行的，是通过api与GitLab Runner交互让gitlab-runner去执行CI。
![](https://cdn.nlark.com/yuque/0/2020/jpeg/1143489/1601088553097-571d72ef-be4f-4bad-9809-3c3429c05a62.jpeg)

优点：

• 跟gitlab集成度非常高 ；

• 不需要部署有gitlab>=8.0 就能直接使用 ；

• runner支持Autoscale ；

• UI可视化，可操作性强，可针对单个流程进行重复执行及报表展示 ；

• CI完全对应你这个代码库，每个项目对应自己CI。

缺点：

• 没有插件，对接第三方系统需要自己实现 ；

• 只能支持gitlab代码仓库。
### Jenkins
Jenkins是一款java开发的功能强大的CI工具,其前身为oracle的Hudson (软件)项目，2011年正式独立出来，Jenkins也是目前非常老牌和主流的CI工具，最早只能支持java语言，后续通过各类语言插件实现多种编程语言支持，Jenkins也是目前插件种类最丰富的CI工具。
![](https://cdn.nlark.com/yuque/0/2020/jpeg/1143489/1601088656264-89964611-519a-46a8-881b-dac37e65bbf8.jpeg)

优点：

• 既有功能完善的UI，也支持pipeline as code ；

• 老牌CI工具运用范围非常广，文档很全面 ；

• 插件生态丰富，基本上想要对接的工具都能找到对应插件 ；

• 支持同时对接多个不同代码仓库。

缺点：

• 对容器、k8s，代码仓库对接配置比较繁琐，目前jenkins基金会推出个jenkins-x子项目专门用于k8s；

• 自定义插件难度大 ；

• 独立的用户权限管理系统，多个开发团队共享一个master，会导致权限配置很困难，但若每个团队用各自Jenkins，又容易导致很多重复性工作。

### 选型
小团队，用的代码管理软件是gitlab，容器编排工具是Kubernetes建议用Gitlab-CI，开箱即用，可以减少很多工作量。

对插件有强烈需求，并且喜欢UI操作流水线的建议用Jenkins。

根据我司现状选择的方案是gitlab-ci
#### 原因：
```
1、业务全面k8s化，没有向裸机部署服务的环境
2、我司及客户使用的也是k8s集群
3、跟gitlab集成度非常高
4、UI可视化，可操作性强，可针对单个流程进行重复执行及报表展示
```
👌！至此容器平台下的CI|CD工具如何选型 阐述完毕！

## gitlab-CI&CD架构图
GitLab-CI 是一套 GitLab 提供给用户使用的持续集成系统，GitLab 8.0 版本以后是默认集成并且默认启用。GitLab-Runner 是配合 GitLab-CI 进行使用的，GitLab 里面每个工程都会定义一些该工程的持续集成脚本，该脚本可配置一个或多个 Stage 例如构建、编译、检测、测试、部署等等。当工程有代码更新时，GitLab 会自动触发 GitLab-CI，此时 CitLab-CI 会找到事先注册好的 GitLab-Runner 通知并触发该 Runner 来执行预先定义好的脚本。
### 我司部署流程图
![](https://cdn.nlark.com/yuque/0/2020/png/1143489/1597022561648-9b3a62e1-f498-4277-891f-9650336d4260.png)
如上图所示，研发同事将代码提交到GitLab后，可以触发.gitlab-ci.yml在GitLab Runner上执行，通过编写.gitlab-ci.yml可以完成很多使用的功能：编译、测试、构建docker镜像、推送到Aliyun镜像仓库、部署到kubernetes集群等；

？部署在公网环境的Gitlab 如何管控部署在内网环境的Kubernetes集群呢？

因为测试环境是在内网，测试环境的k8s集群无法通过外网连接，如果gitlab-runner是部署在外部的裸机上，将无法和测试环境k8s对接，如果gitlab-runner是部署在k8s集群上，那么如何实现runner job跑在对应的分支上呢？
    我的方案是通过制作三个kubectl 镜像分别控制三个集群，在gitlab-ci脚本中引用。
    
？部署在Kubernetes上的Gitlab-runner如何实现缓存呢
这里我选择minio作为环境的存储

### 网上部署流程图
传统的 GitLab-Runner 我们一般会选择某个或某几个机器上，可以 Docker 安装启动亦或是直接源码安装启动，都会存在一些痛点问题，比如发生单点故障，那么该机器的所有 Runner 就不可用了；每个 Runner 所在机器环境不一样，以便来完成不同类型的 Stage 操作，但是这种差异化配置导致管理起来很麻烦；资源分配不平衡，有的 Runner 运行工程脚本出现拥塞时，而有的 Runner 缺处于空闲状态；资源有浪费，当 Runner 处于空闲状态时，也没有安全释放掉资源。因此，为了解决这些痛点，我们可以采用在 Kubernetes 集群中运行 GitLab-Runner 来动态执行 GitLab-CI 脚本任务，它整个流程如下图：
![](https://cdn.nlark.com/yuque/0/2020/png/639340/1592043818659-d9eb6c67-8474-43c3-a993-92c1a5d2605c.png?x-oss-process=image%2Fwatermark%2Ctype_d3F5LW1pY3JvaGVp%2Csize_10%2Ctext_6L-b5Ye755qE6I-c6bif6L-Q57u0%2Ccolor_FFFFFF%2Cshadow_50%2Ct_80%2Cg_se%2Cx_10%2Cy_10%2Fresize%2Cw_1300)

这种方式带来的好处有：

• 服务高可用，当某个节点出现故障时，Kubernetes 会自动创建一个新的 GitLab-Runner 容器，并挂载同样的 Runner 配置，使服务达到高可用。

• 动态伸缩，合理使用资源，每次运行脚本任务时，Gitlab-Runner 会自动创建一个或多个新的临时 Runner，当任务执行完毕后，临时 Runner 会自动注销并删除容器，资源自动释放，而且 Kubernetes 会根据每个节点资源的使用情况，动态分配临时 Runner 到空闲的节点上创建，降低出现因某节点资源利用率高，还排队等待在该节点的情况。

• 扩展性好，当 Kubernetes 集群的资源严重不足而导致临时 Runner 排队等待时，可以很容易的添加一个 Kubernetes Node 到集群中，从而实现横向扩展。

### gitlab-runner的类型
从使用者的维度来看，GitLab Runner的类型分为shared和specific两种：

如果您想创建的GitLab Runner给所有GitLab仓库使用，就要创建shared类型；

如果您的GitLab Runner只用于给某个固定的Gitlab仓库，就要创建specific类型；

选择的是shared类型
👌！至此gitlab-CI|CD架构图 阐述完毕！
## gitlab-ci使用的有关文档
1、GitLab的CI自动编译的实现（基础）：https://www.jianshu.com/p/b69304279c5f

2、gitlab-ci.yml 配置Gitlab pipeline以达到持续集成的方法 （参数讲解）：https://www.jianshu.com/p/617f035f01b8

3、持续集成之gitlab-ci.yml（命令及示例讲解）：https://segmentfault.com/a/1190000019540360

4、gitlab 官方文档地址（官）：https://docs.gitlab.com/ee/ci/yaml/README.html

多找几篇博文 分析一下，然后自己组合多测试几个就差不多，没啥难度的。

👌！至此gitlab-ci使用的有关文档 阐述完毕！
## 部署环境
### 部署kubernetes集群
参考此仓库：gitlab.realibox.cn:realicloud/devops/aliyun-k8s-config.git
注：此仓库整体可用，但部分清单在k8s 1.16.9版本不再使用，注意。
### 部署gitlab
新购1台 4C8G的gitlab代码托管服务器
![](https://cdn.nlark.com/yuque/0/2020/png/1143489/1595235697761-b9b99aab-a86f-48a4-8782-bb4b8ef7db5f.png?x-oss-process=image%2Fresize%2Cw_1300)
```
yum install vim gcc gcc-c++ wget net-tools lrzsz iotop lsof iotop bash-completion -y
yum install curl policycoreutils openssh-server openssh-clients postfix -y
systemctl disable firewalld
sed -i '/SELINUX/s/enforcing/disabled/' /etc/sysconfig/selinux
wget https://mirrors.tuna.tsinghua.edu.cn/gitlab-ce/yum/el7/gitlab-ce-13.1.4-ce.0.el7.x86_64.rpm
yum localinstall gitlab-ce-13.1.4-ce.0.el7.x86_64.rpm
cp /etc/gitlab/gitlab.rb{,.bak}
vim /etc/gitlab/gitlab.rb
gitlab-ctl reconfigure
ss -lntup

#证书
cd tools/
unzip 4364022_gitlab.realibox.cn_other.zip   #ali申请的免费证书，也可以用cert-manager生成
mv 4364022_gitlab.realibox.cn.pem  /etc/gitlab/ssl/server.crt
mv 4364022_gitlab.realibox.cn.key /etc/gitlab/ssl/server.keyhist 
gitlab-ctl restart 
域名解析 
```
不允许用户注册
![](https://cdn.nlark.com/yuque/0/2020/png/1143489/1595242323423-6cdacc8b-4aab-4a6e-89e9-5f65db91bf14.png?x-oss-process=image%2Fresize%2Cw_1300)
### 部署gitlab-runner 
将gitlab-runner部署在k8s集群中，此处有docker in docker的问题,所以要共享宿主机的docker sock，注意需要用到缓存minio
```
#部署minio
minio作为一个独立的服务部署，我将用docker部署在服务器：47.106.69.126节点
在宿主机准备两个目录，分别存储minio的配置和文件，执行以下命令：
mkdir -p /data/minio/gitlab_runner \
&& chmod -R 777 /data/minio/gitlab_runner \
&& mkdir -p /data/minio/config \
&& chmod -R 777 /data/minio/config
执行docker命令创建minio服务，指定服务端口是9000，并且指定了access key(最短三位)和secret key(最短八位)：
docker run -p 9000:9000 --name minio \
-d --restart=always \
-e "MINIO_ACCESS_KEY=realibox" \
-e "MINIO_SECRET_KEY=Realibox2020" \
-v /data/minio/gitlab_runner:/gitlab_runner \
-v /data/minio/config:/root/.minio \
minio/minio server /gitlab_runner

浏览器访问，输入access key和secret key后登录成功
点击红框中的图标，创建一个bucket，名为runner


#安装helm
wget https://get.helm.sh/helm-v3.1.2-linux-amd64.tar.gz
tar xf helm-v3.1.2-linux-amd64.tar.gz 
mv linux-amd64/helm /usr/local/bin/
chmod +x /usr/local/bin/helm
helm version

##安装gitlab-runner
#创建名为gitlab-runner的namespace：
kubectl create namespace gitlab-runner
#创建一个secret，把minio的access key和secret key存进去，在后面配置cache的时候会用到：
kubectl create secret generic s3access \
--from-literal=accesskey="realibox" \
--from-literal=secretkey="Realibox2020" -n gitlab-runner

#用helm部署GitLab Runner
helm repo add gitlab https://charts.gitlab.io
helm fetch gitlab/gitlab-runner
helm install --name-template gitlab-runner -f values.yaml . --namespace gitlab-runner

#卸载gitlab-runner
#helm  uninstall  gitlab-runner --namespace gitlab-runner
```
获取Runners的token
![](https://cdn.nlark.com/yuque/0/2020/png/1143489/1601101316574-53383ea0-7ecd-4f96-ba91-07a305a3385f.png)
### 部署镜像仓库
我司目前选择的镜像仓库是阿里云的镜像仓库，需要RAM权限。
![](https://cdn.nlark.com/yuque/0/2020/png/1143489/1601101785152-e1c5bb2d-7a17-42a7-8a75-806de0037e67.png)
👌！至此部署环境 阐述完毕！
## 联调
这里的联调分为三部分：

1、gitlab-ci与k8s集群联调 

2、gitlab-ci与ali镜像仓库联调 

3、整体联调

设置必要的gitlab CI/CD 环境变量
![](https://cdn.nlark.com/yuque/0/2020/png/1143489/1601103364699-c6651142-8439-4afc-8552-4ea8defe02fa.png)

### gitlab-ci与k8s集群联调
制作kubectl镜像
```
# pwd
/root/linkun/gitlab-runner/test
# ll
total 20
drwxr-xr-x 2 root root 4096 Jul 23 16:38 ./
drwxr-xr-x 4 root root 4096 Jul 23 15:55 ../
-rw-r--r-- 1 root root 5451 Jul 23 16:31 config
-rw-r--r-- 1 root root  545 Jul 23 16:38 Dockerfile
##此处的config是k8s集群的/root/.kube/config  安全性，再次不展示
# cat Dockerfile 
FROM alpine:3.8

MAINTAINER zisefeizhu <linkun@realibox.com>

#VERSION 尽量k8s集群版本号一致
ENV KUBE_LATEST_VERSION="v1.16.9"

RUN apk add --update ca-certificates \
 && apk add --update -t deps curl \
 && apk add --update gettext \
 && apk add --update git \
 && curl -L https://storage.googleapis.com/kubernetes-release/release/${KUBE_LATEST_VERSION}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl \
 && chmod +x /usr/local/bin/kubectl \
 && apk del --purge deps \
 && rm /var/cache/apk/* \
 && mkdir /root/.kube

# config为对应集群得kubeconf
COPY config  /root/.kube/
ENTRYPOINT ["kubectl"]
CMD ["--help"]

# docker build -t registry.cn-shenzhen.aliyuncs.com/realibox-baseimage/kubectl:test .
# docker push registry.cn-shenzhen.aliyuncs.com/zrealibox-baseimage/kubectl:test
```
简单demo测试：观察k8s gitlab-runner namespace pod 和 gitlab ci/cd的job 变化状况
```
# ll
total 48
drwxr-xr-x  15 root  wheel   480B Sep 26 15:07 .git
-rw-r--r--   1 root  wheel   240B Sep 26 15:07 .gitlab-ci.yml
-rw-r--r--   1 root  wheel    19K Sep 26 15:10 README.md
drwxr-xr-x   3 root  wheel    96B Sep 26 12:00 gitlab-rb

# gitlab-ci.yml
stages:
  - kubectl

## gitlab-ci与k8s集群联调 demo测试
deploy-stage-kubectl:
  tags:
    - stage
  image: "${KUBECTL_STAGE}"
  stage: kubectl
  script:
    - echo "gitlab-ci与k8s集群联调 demo测试 success"
  only:
    - master

# pod 变化tl get po -n gitlab-runner -w
NAME                                           READY   STATUS    RESTARTS   AGE
gitlab-runner-gitlab-runner-56f565cb4d-hjgjq   1/1     Running   0          31d
gitlab-runner-gitlab-runner-56f565cb4d-p7jxp   1/1     Running   0          31d
runner-zeqgvr3-project-260-concurrent-0qbrvc   0/2     Pending   0          0s
runner-zeqgvr3-project-260-concurrent-0qbrvc   0/2     Pending   0          0s
runner-zeqgvr3-project-260-concurrent-0qbrvc   0/2     ContainerCreating   0          0s
runner-zeqgvr3-project-260-concurrent-0qbrvc   2/2     Running             0          3s
runner-zeqgvr3-project-260-concurrent-0qbrvc   2/2     Terminating         0          4s
runner-zeqgvr3-project-260-concurrent-0qbrvc   2/2     Terminating         0          4s
```
![](https://cdn.nlark.com/yuque/0/2020/png/1143489/1601104436508-8c287355-fb75-4fa8-8923-280b991f91c9.png)
### gitlab-ci与ali镜像仓库联调

demo测试：下载测试镜像 修改镜像tag 并上传到ali realibox 镜像仓库命名空间
```
#  ll
total 56
drwxr-xr-x  15 root  wheel   480B Sep 26 15:28 .git
-rw-r--r--   1 root  wheel   492B Sep 26 15:27 .gitlab-ci.yml
-rw-r--r--   1 root  wheel    20K Sep 26 15:32 README.md
drwxr-xr-x   3 root  wheel    96B Sep 26 12:00 gitlab-rb
drwxr-xr-x   3 root  wheel    96B Sep 26 15:22 liantiao

# gitlab-ci.yml
before_script:
  - export REGISTRY_IMAGE="${ALI_IMAGE_REGISTRY}"/realibox/"${CI_PROJECT_NAME}":"${CI_COMMIT_REF_NAME//\//-}"-"$CI_PIPELINE_ID"

stages:
  - build

image_build:
  tags:
    - stage
  stage: build
  image: docker:latest
  script:
    - docker login -u "${ALI_IMAGE_USER}" -p "${ALI_IMAGE_PASSWORD}" "${ALI_IMAGE_REGISTRY}"
    - docker pull golang:1.14.3-alpine
    - docker tag golang:1.14.3-alpine "${REGISTRY_IMAGE}"
    - docker push "${REGISTRY_IMAGE}"
  only:
    - master
```
![](https://cdn.nlark.com/yuque/0/2020/png/1143489/1601105654538-da239dba-ba88-4baf-8278-5a7b84aa94c1.png)

![](https://cdn.nlark.com/yuque/0/2020/png/1143489/1601105717193-1d8abb8b-0ebc-49c8-8b62-40f4b2e967ad.png)
### 整体联调
demo测试：使用经典的测试项目gitlab-ci-k8s-demo
```
##  目录结构
#  ll
total 160
drwxr-xr-x  13 root  wheel   416B Sep 27 14:11 .git
-rw-r--r--   1 root  wheel   1.4K Sep 27 11:37 .gitlab-ci.yml
-rw-r--r--   1 root  wheel   299B Sep 27 11:54 Dockerfile
-rw-r--r--   1 root  wheel    23K Sep 27 14:16 README.md
drwxr-xr-x   3 root  wheel    96B Sep 27 11:37 gitlab-rb
drwxr-xr-x  12 root  wheel   384B Sep 27 11:37 gitlab-runner
-rw-r--r--   1 root  wheel   143B Sep 27 11:37 go.mod
-rw-r--r--   1 root  wheel    39K Sep 27 11:37 go.sum
drwxr-xr-x   4 root  wheel   128B Sep 27 11:37 liantiao
-rw-r--r--   1 root  wheel   1.2K Sep 27 14:10 main.go
drwxr-xr-x   8 root  wheel   256B Sep 27 14:14 manifests


# main.go
package main

import (
	"flag"
	"net/http"
	"os"
	"time"

	log "github.com/sirupsen/logrus"
	"github.com/gorilla/handlers"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"github.com/prometheus/common/version"
)

var ready = false
var addr = flag.String("listen-address", ":8000", "The address to listen on for HTTP requests.")

func main() {
	flag.Parse()
	log.Info("Starting presentation-gitlab-k8s application..")
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		hostname, _ := os.Hostname()
		w.Write([]byte("Hello Golang In Gitlab CI!!\n"))
		w.Write([]byte("Hostname: " + hostname + "\n"))
		w.Write([]byte("Version Info:\n"))
		w.Write([]byte(version.Print("server") + "\n"))
	})
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		if ready {
			w.WriteHeader(http.StatusOK)
			w.Write([]byte("200"))
		} else {
			w.WriteHeader(http.StatusInternalServerError)
			w.Write([]byte("500"))
		}
	})
	http.Handle("/metrics", promhttp.Handler())
	go func() {
		<-time.After(5 * time.Second)
		ready = true
		log.Info("Application is ready!")
	}()
	log.Info("Listen on " + *addr)
	log.Fatal(http.ListenAndServe(*addr, handlers.LoggingHandler(os.Stdout, http.DefaultServeMux)))
}

##本地测试
# go run main.go 
INFO[0000] Starting presentation-gitlab-k8s application.. 
INFO[0000] Listen on :8000                              
INFO[0005] Application is ready!                        

##docker测试
FROM golang:1.14.3-alpine as build

WORKDIR /app
COPY . /app
RUN go env -w GO111MODULE=on \
    && go env -w GOPROXY=https://goproxy.io,direct
RUN go build -o server main.go && \
    chmod +x ./server

FROM alpine:latest

WORKDIR /app
COPY --from=build /app/server /app
EXPOSE 8000
CMD ["./server"]

docker build -t test-ci:v1 .

docker run --name test test-ci:v1
time="2020-09-26T10:39:49Z" level=info msg="Starting presentation-gitlab-k8s application.."
time="2020-09-26T10:39:49Z" level=info msg="Listen on :8000"
time="2020-09-26T10:39:54Z" level=info msg="Application is ready!"


##k8s部署
.gitlab-ci.yml
###########################################################################
#                                                                         #
#General intention：Cluster reconstruction project gitlab-k8s-ci-demo     #
#The files involved in cicd are：.gitlab-ci.yml、manifests、Dockerfile     #
#by: zisefeizhu [linkun]                                                  #
#time: 2020-09-27                                                         #
#                                                                         #
###########################################################################

before_script:
  - export REGISTRY_IMAGE="${ALI_IMAGE_REGISTRY}"/realibox/"${CI_PROJECT_NAME}":${CvI_COMMIT_REF_NAME//\//-}-$CI_PIPELINE_ID

variables:
  PORT: 8000

stages:
  - test
  - build
  - kubectl

test:
  tags:
    - stage
  stage: test
  script:
    - echo "ci|cd running"
  only:
    - master

image-realibox-studio-build:
  tags:
    - stage
  stage: build
  image: docker:latest
  script:
    - docker login -u "${ALI_IMAGE_USER}" -p "${ALI_IMAGE_PASSWORD}" "${ALI_IMAGE_REGISTRY}"
    - docker build . -t $REGISTRY_IMAGE
    - docker push "${REGISTRY_IMAGE}"
  only:
    - master

deploy-stage-kubectl:
  tags:
    - stage
  image: "${KUBECTL_STAGE}"
  stage: kubectl
  variables:
    NAMESPACE: test
  script:
    - cd manifests/
    - sh -x kubernetes.sh
  only:
    - master

##k8s资源清单 manifests目录下
# ll
total 40
-rw-r--r--  1 root  wheel   771B Sep 27 14:14 deployment.yaml
drwxr-xr-x  3 root  wheel    96B Sep 27 11:37 ingress
-rw-r--r--  1 root  wheel   3.4K Sep 27 14:02 kubernetes.sh
-rw-r--r--  1 root  wheel    62B Sep 27 11:37 realibox-namespace.yaml
-rw-r--r--  1 root  wheel   221B Sep 27 11:37 secret-namespace.sh
-rw-r--r--  1 root  wheel   424B Sep 27 13:58 svc.yaml

##kubernetes.sh为核心部署清单
##########################################################################
#Author:                     zisefeizhu
#QQ:                         2********0
#Date:                       2020-09-27
#FileName:                   kubernetes.sh
#URL:                        https://www.cnblogs.com/zisefeizhu/
#Description:                The test script
#Copyright (C):              2020 All rights reserved
##########################################################################
#!/bin/bash

echo -e "\033[45;30m NAMESPACE \033[0m"
kubectl get ns | grep -wq $NAMESPACE
if [ $? -eq 0 ]; then
  echo "The namespace already exists and does not need to be created"
else
  ###namespace
  echo "The namespace does not exist and needs to be created"
  sed -i "s/__NAMESPACE__/${NAMESPACE}/g" realibox-namespace.yaml
  cat realibox-namespace.yaml
	kubectl apply -f realibox-namespace.yaml
fi

echo -e "\033[45;30m SECRETS \033[0m"
kubectl get secrets -n $NAMESPACE | grep -wq $NAMESPACE-secret
if [ $? -eq 0 ]; then
  echo "Secret already exists, no need to create it"
else
  ###secret
  echo "Secret does not exist. It needs to be created"
  sed -i "s/__ALI_IMAGE_REGISTRY_PRODUCTION__/${ALI_IMAGE_REGISTRY_PRODUCTION}/" secret-namespace.sh
  sed -i "s/__ALI_IMAGE_USER__/${ALI_IMAGE_USER}/" secret-namespace.sh
  sed -i "s/__ALI_IMAGE_PASSWORD__/${ALI_IMAGE_PASSWORD}/" secret-namespace.sh
  sed -i "s/__NAMESPACE__/${NAMESPACE}/g" secret-namespace.sh
  cat secret-namespace.sh
  sh -x secret-namespace.sh
fi

echo -e "\033[45;30m DEPLOYMENT \033[0m"
kubectl get deployment -n $NAMESPACE | grep -wq ${CI_PROJECT_NAME}
if [ $? -eq 0 ]; then
  echo "=> Patching deployment to force image update."
  kubectl patch -f deployment.yaml -p "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"ci-last-updated\":\"$(date +'%s')\"}}}}}"
  kubectl set image deployment ${CI_PROJECT_NAME} ${CI_PROJECT_NAME}=${REGISTRY_IMAGE}
else
  ###deployment
  sed -i "s/__NAMESPACE__/${NAMESPACE}/g" deployment.yaml
  sed -i "s/__CI_PROJECT_NAME__/${CI_PROJECT_NAME}/g"  deployment.yaml
  sed -i "s/__VERSION__/"${CI_COMMIT_REF_NAME//\//-}-$CI_PIPELINE_ID"/" deployment.yaml
  sed -i "s/__PORT__/${PORT}/g" deployment.yaml
  cat deployment.yaml
  kubectl apply -f deployment.yaml
fi

echo -e "\033[45;30m SERVICE \033[0m"
kubectl get service -n $NAMESPACE  | grep -wq ${CI_PROJECT_NAME}
if [ $? -eq 0 ]; then
  echo "Service already exists, no need to create it"
else
  ###svc
  echo "Service does not exist. It needs to be created"
  sed -i "s/__NAMESPACE__/${NAMESPACE}/g" svc.yaml
  sed -i "s/__PORT__/${PORT}/g" svc.yaml
  sed -i "s/__CI_PROJECT_NAME__/${CI_PROJECT_NAME}/g" svc.yaml
  cat svc.yaml
	kubectl apply -f svc.yaml
fi

echo -e "\033[45;30m INGRESS \033[0m"
kubectl get ingress -n $NAMESPACE  | grep -wq ${CI_PROJECT_NAME}
if [ $? -eq 0 ]; then
  echo "Ingress already exists, no need to create it"
else
  ###ingress
  echo "Ingress does not exist. It needs to be created"
  sed -i "s/__NAMESPACE__/${NAMESPACE}/g" ingress/${CI_COMMIT_REF_NAME//\//-}.yaml
  sed -i "s/__PORT__/${PORT}/g" ingress/${CI_COMMIT_REF_NAME//\//-}.yaml
  sed -i "s/__CI_PROJECT_NAME__/${CI_PROJECT_NAME}/g" ingress/${CI_COMMIT_REF_NAME//\//-}.yaml
  cat ingress/${CI_COMMIT_REF_NAME//\//-}.yaml
  kubectl apply -f ingress/${CI_COMMIT_REF_NAME//\//-}.yaml
fi

echo -e "\033[45;30m HPA \033[0m"
kubectl get hpa -n $NAMESPACE  | grep -wq ${CI_PROJECT_NAME}
if [ $? -eq 0 ]; then
  echo "HPA already exists, no need to create it"
else
  ###HPA
  echo "HPA does not exist. It needs to be created"
  sed -i "s/__NAMESPACE__/${NAMESPACE}/g" hpa.yaml
  sed -i "s/__CI_PROJECT_NAME__/${CI_PROJECT_NAME}/g" hpa.yaml
  cat hpa.yaml
  kubectl apply -f hpa.yaml
fi

echo -e "\033[45;30m Final resource allocation \033[0m"
kubectl rollout status -f deployment.yaml
kubectl get all -l name=${CI_PROJECT_NAME} -n ${NAMESPACE}


##realibox-namespace.yaml 为项目部署名称空间
apiVersion: v1
kind: Namespace
metadata:
  name: __NAMESPACE__

##secret-namespace.sh为上述名称空间的镜像拉取认证
因为我司有多套k8s环境，处于几个账号下，为了方便管理这里使用公网下载镜像。因为下载是上传的10倍网速，所以下载使用公网速度也是很快的。
#!/bin/bash
kubectl create secret docker-registry __NAMESPACE__-secret --docker-server=__ALI_IMAGE_REGISTRY_PRODUCTION__  --docker-username='__ALI_IMAGE_USER__' --docker-password='__ALI_IMAGE_PASSWORD__'  -n __NAMESPACE__ 

##deployment.yaml 无状态控制器，管理pod
apiVersion: apps/v1
kind: Deployment
metadata:
  name: __CI_PROJECT_NAME__
  namespace: __NAMESPACE__
  labels:
    name: __CI_PROJECT_NAME__
spec:
  replicas: 1
  selector:
    matchLabels:
      name: __CI_PROJECT_NAME__
  template:
    metadata:
      labels:
        name: __CI_PROJECT_NAME__
    spec:
      imagePullSecrets:
        - name: __NAMESPACE__-secret
      containers:
        - name: __CI_PROJECT_NAME__
          image: registry.cn-shenzhen.aliyuncs.com/realibox/__CI_PROJECT_NAME__:__VERSION__
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: __PORT__
          env:
            - name: TZ
              value: Asia/Shanghai
          resources:
            limits:
              cpu: 250m
              memory: 128Mi
            requests:
              cpu: 250m
              memory: 128Mi
          envFrom: ##向容器中提供配置文件或环境变量来实现不同配置,一般而言后端服务可能需要做configmap和secret
            - configMapRef:
                name: __CI_PROJECT_NAME__

##svc.yaml   每一个service可以理解为一个微服务，Service能够提供负载均衡的能力
apiVersion: v1
kind: Service
metadata:
  name: __CI_PROJECT_NAME__
  namespace: __NAMESPACE__
  labels:
    name: __CI_PROJECT_NAME__
  annotations:                      ##注解，将元数据附加到Kubernetes对象。通常我司的服务没必要做注解
    prometheus.io/scrape: "true"
    prometheus.io/port: "__PORT__"
    prometheus.io/scheme: "http"
    prometheus.io/path: "/metrics"
spec:
  type: ClusterIP
  selector:
    name: __CI_PROJECT_NAME__
  ports:
    - name: http
      port: __PORT__
      targetPort: __PORT__

##ingress/${CI_COMMIT_REF_NAME//\//-}.yaml  不同的环境及不同的名称空间有不同的域名定义规则，所以此部分无法做到整合，根据分支名区分环境的规则来做ingress的书写
##例如：production/test分支对应的ingress为igress/production-test.yaml
##ingress/master.yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: __CI_PROJECT_NAME__
  namespace: __NAMESPACE__
  labels:
    name: __CI_PROJECT_NAME__
spec:
  tls:
    - hosts:
        - "*.realibox.cn"
      secretName: realibox-cn
  rules:
    - host: go.realibox.cn
      http:
        paths:
          - path: /
            backend:
              serviceName: __CI_PROJECT_NAME__
              servicePort: __PORT__

##hpa.yaml 实现业务pod的自动扩缩容，这里的配置是根据CPU和内存来定的。
apiVersion: autoscaling/v2beta1
kind: HorizontalPodAutoscaler
metadata:
  name: __CI_PROJECT_NAME__
  namespace: __NAMESPACE__
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: __CI_PROJECT_NAME__
  minReplicas: 1
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        targetAverageUtilization: 80
    - type: Resource
      resource:
        name: memory
        targetAverageValue: 100Mi

👌！有关k8s部署的资源清单到此结束
```
#### 测试部署
```
git add .
git commit -m "整体连调"
git push 
```
自动输出ci/cd
![](https://cdn.nlark.com/yuque/0/2020/png/1143489/1601260285996-20890663-5f6e-4764-b733-ed84f3eb3fba.png)
返回部署结果
![](https://cdn.nlark.com/yuque/0/2020/png/1143489/1601260355942-fa494104-df6d-4159-bc8c-34b504af0792.png)
k8s终端查看
```
kubectl get all -n test
NAME                                  READY   STATUS    RESTARTS   AGE
pod/aliyun-k8s-cicd-94f785d5f-m5rxg   1/1     Running   0          3m57s

NAME                      TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)    AGE
service/aliyun-k8s-cicd   ClusterIP   10.0.30.229   <none>        8000/TCP   3m57s

NAME                              READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/aliyun-k8s-cicd   1/1     1            1           3m57s

NAME                                        DESIRED   CURRENT   READY   AGE
replicaset.apps/aliyun-k8s-cicd-94f785d5f   1         1         1       3m57s

NAME                                                  REFERENCE                    TARGETS                 MINPODS   MAXPODS   REPLICAS   AGE
horizontalpodautoscaler.autoscaling/aliyun-k8s-cicd   Deployment/aliyun-k8s-cicd   7712768/100Mi, 0%/80%   1
```
浏览器访问
![](https://cdn.nlark.com/yuque/0/2020/png/1143489/1601260605900-78dcd3bc-99c6-4cd6-91cb-37631431f6b6.png)
压力测试 -- 自动扩容
```
# cat ab.yaml
kind: Deployment
apiVersion: extensions/v1beta1
metadata:
  name: apache
  namespace: default
  labels:
    name: apache

spec:
  #replicas: 3  #起的pod数
  selector:
    matchLabels:
      name: apache
  template:
    metadata:
      labels:
        name: apache
    spec:
      containers:
      - name: apache
        image: httpd   #使用镜像
        command: ["ab","-c 4000","-n 1000000"]    #执行命令
        args: ["http://go.realibox.cn/"]    #压测域名
        ports:
        - name: http
          containerPort: 80
```
![](https://cdn.nlark.com/yuque/0/2020/png/1143489/1601261138613-8e5d7a18-f823-43cd-8fbf-8e1aa1b066b8.png)
压力测试 -- 自动缩容
```
# kubectl delete deployment apache
deployment.extensions "apache" deleted
```
![](https://cdn.nlark.com/yuque/0/2020/png/1143489/1601261525039-8090f4d0-4ac9-4359-81c4-d69c09a4b6ce.png)
👌！至此部署联调 阐述完毕！

## gitlab的使用说明
### 分支使用说明
分支类比图：

![](https://cdn.nlark.com/yuque/0/2020/png/1143489/1601261834075-db95569b-ed32-4ab9-b448-1240697fbe43.png)

分支作用申明：

1、多集群环境【如 我司环境、东风环境等】

⭕️ developer：代码同步分支不做部署处理，最新代码所在分支

⭕ realibox/studio:  realibox往预发环境发送的代码分支  新版测试

⭕ stage/xxx:  stage往测试环境发送的代码分支  xxx是集群环境(如：studio 预发环境旧版测试)

⭕ production/xxx:  production往生产环境发送的代码分支  xxx是集群环境(如：realibox 我司生产环境)

2、单集群环境【如 我司环境】

⭕ developer：代码同步分支不做部署处理，最新代码所在分支

⭕ realibox:  realibox往预发环境发送的代码分支  新版测试

⭕ stage:  stage往预发环境发送的代码分支 旧版测试

⭕ master:  master往生产环境发送的代码分支 
### 代码管理规范
代码管理规范.md
### gitlab备份的有关说明
gitlab备份.md
👌！至此gitlab的使用说明 阐述完毕！

## 多环境部署
![](https://cdn.nlark.com/yuque/0/2020/png/1143489/1601289392390-f0545cd5-a923-4f75-b6fc-4522884379d4.png)
### 部署清单
.gitlab-ci.yaml
```
###########################################################################
#                                                                         #
#General intention：Cluster reconstruction project gitlab-k8s-ci-demo     #
#The files involved in cicd are：.gitlab-ci.yml、manifests、Dockerfile     #
#by: zisefeizhu [linkun]                                                  #
#time: 2020-09-28                                                        #
#                                                                         #
###########################################################################

before_script:
  - export REGISTRY_IMAGE="${ALI_IMAGE_REGISTRY}"/realibox/"${CI_PROJECT_NAME}":${CI_COMMIT_REF_NAME//\//-}-$CI_PIPELINE_ID

variables:
  PORT: 8000

stages:
  - test
  - build
  - kubectl

test:
  tags:
    - stage
  stage: test
  script:
    - echo "ci|cd running"
  only:
    - realibox/studio
    - stage/studio
    - stage/venucia
    - stage/pppharmapack
    - production/realibox
    - production/vencia
    - production/pppharmapack

##后端可以共用一个打包镜像流程
image-build:
  tags:
    - stage
  stage: build
  image: docker:latest
  script:
    - docker login -u "${ALI_IMAGE_USER}" -p "${ALI_IMAGE_PASSWORD}" "${ALI_IMAGE_REGISTRY}"
    - docker build . -t $REGISTRY_IMAGE
    - docker push "${REGISTRY_IMAGE}"
  only:
    - realibox/studio
    - stage/studio
    - stage/venucia
    - stage/pppharmapack
    - production/realibox
    - production/vencia
    - production/pppharmapack

##realibox-studio 环境
realibox-studio-kubectl:
  tags:
    - stage
  image: "${KUBECTL_STAGE}"
  stage: kubectl
  variables:
    NAMESPACE: realibox
  script:
    - cd manifests/
    - sh -x kubernetes.sh
  only:
    - realibox/studio

##stage-studio 环境
stage-studio-kubectl:
  tags:
    - stage
  image: "${KUBECTL_STAGE}"
  stage: kubectl
  variables:
    NAMESPACE: stage
  script:
    - cd manifests/
    - sh -x kubernetes.sh
  only:
    - stage/studio

##stage-venucia 环境
stage-venucia-kubectl:
  tags:
    - dongfeng
  image: "${KUBECTL_DONGFENG}"
  stage: kubectl
  variables:
    NAMESPACE: stage-venucia
  script:
    - cd manifests/
    - sh -x kubernetes.sh
  only:
    - stage/venucia

##stage-pppharmapack 环境
stage-pppharmapack-kubectl:
  tags:
    - famajia
  image: "${KUBECTL_FAMAJIA}"
  stage: kubectl
  variables:
    NAMESPACE: stage-pppharmapack
  script:
    - cd manifests/
    - sh -x kubernetes.sh
  only:
    - stage/pppharmapack

##production-realibox 环境
production-realibox-kubectl:
  tags:
    - dongfeng
  image: "${KUBECTL_DONGFENG}"
  stage: kubectl
  variables:
    NAMESPACE: realibox
  script:
    - cd manifests/
    - sh -x kubernetes.sh
  only:
    - production/realibox

##production-vencia 环境
production-vencia-kubectl:
  tags:
    - dongfeng
  image: "${KUBECTL_DONGFENG}"
  stage: kubectl
  variables:
    NAMESPACE: production-venucia
  script:
    - cd manifests/
    - sh -x kubernetes.sh
  only:
    - production/vencia

##production-pppharmapack 环境
production-pppharmapack-kubectl:
  tags:
    - famajia
  image: "${KUBECTL_FAMAJIA}"
  stage: kubectl
  variables:
    NAMESPACE: production-pppharmapack
  script:
    - cd manifests/
    - sh -x kubernetes.sh
  only:
    - production/pppharmapack
```
👌！至此多环境部署 阐述完毕！
## 单环境部署
![](https://cdn.nlark.com/yuque/0/2020/png/1143489/1601289286312-7f35a9c2-417a-4f0d-8d62-f1daffcf97b5.png)
### 部署清单
.gitlab-ci.yaml
```
###########################################################################
#                                                                         #
#General intention：Cluster reconstruction project gitlab-k8s-ci-demo     #
#The files involved in cicd are：.gitlab-ci.yml、manifests、Dockerfile     #
#by: zisefeizhu [linkun]                                                  #
#time: 2020-09-28                                                        #
#                                                                         #
###########################################################################

before_script:
  - export REGISTRY_IMAGE="${ALI_IMAGE_REGISTRY}"/realibox/"${CI_PROJECT_NAME}":${CI_COMMIT_REF_NAME//\//-}-$CI_PIPELINE_ID

variables:
  PORT: 8000

stages:
  - test
  - build
  - kubectl

test:
  tags:
    - stage
  stage: test
  script:
    - echo "ci|cd running"
  only:
    - master
    - realibox
    - stage

##后端可以共用一个打包镜像流程
image-build:
  tags:
    - stage
  stage: build
  image: docker:latest
  script:
    - docker login -u "${ALI_IMAGE_USER}" -p "${ALI_IMAGE_PASSWORD}" "${ALI_IMAGE_REGISTRY}"
    - docker build . -t $REGISTRY_IMAGE
    - docker push "${REGISTRY_IMAGE}"
  only:
    - master
    - realibox
    - stage

##stage 环境
stage-kubectl:
  tags:
    - stage
  image: "${KUBECTL_STAGE}"
  stage: kubectl
  variables:
    NAMESPACE: stage
  script:
    - cd manifests/
    - sh -x kubernetes.sh
  only:
    - stage

##realibox环境
stage-studio-kubectl:
  tags:
    - stage
  image: "${KUBECTL_STAGE}"
  stage: kubectl
  variables:
    NAMESPACE: realibox
  script:
    - cd manifests/
    - sh -x kubernetes.sh
  only:
    - realibox

##master 环境
master-kubectl:
  tags:
    - stage
  image: "${KUBECTL_STAGE}"
  stage: kubectl
  variables:
    NAMESPACE: realibox
  script:
    - cd manifests/
    - sh -x kubernetes.sh
  only:
    - master
```
👌！至此单环境部署 阐述完毕！
## 存储考量
在上述的多环境部署和单环境部署中都没有考虑到存储的问题，大多数服务难以用到存储，所以将存储单列出来。

了解该部分之前，需要大致看一下此文档：在阿里云k8s集群上使用nas做动态存储.md

分别给出CSI 和flexvolume 的两种部署方式

### 目录结构
![](https://cdn.nlark.com/yuque/0/2020/png/1143489/1601348420063-b850d651-45d1-4341-9dfb-4cdd9548537e.png)
注：这里的kubernetes.sh实则是属于manifests目录的。 存储插件只能存在一个。
```
##########################################################################
#Author:                     zisefeizhu
#QQ:                         2********0
#Date:                       2020-09-27
#FileName:                   kubernetes.sh
#URL:                        https://www.cnblogs.com/zisefeizhu/
#Description:                The test script
#Copyright (C):              2020 All rights reserved
##########################################################################
#!/bin/bash

echo -e "\033[45;30m NAMESPACE \033[0m"
kubectl get ns | grep -wq $NAMESPACE
if [ $? -eq 0 ]; then
  echo "The namespace already exists and does not need to be created"
else
  ###namespace
  echo "The namespace does not exist and needs to be created"
  sed -i "s/__NAMESPACE__/${NAMESPACE}/g" realibox-namespace.yaml
  cat realibox-namespace.yaml
	kubectl apply -f realibox-namespace.yaml
fi

echo -e "\033[45;30m SECRETS \033[0m"
kubectl get secrets -n $NAMESPACE | grep -wq $NAMESPACE-secret
if [ $? -eq 0 ]; then
  echo "Secret already exists, no need to create it"
else
  ###secret
  echo "Secret does not exist. It needs to be created"
  sed -i "s/__ALI_IMAGE_REGISTRY_PRODUCTION__/${ALI_IMAGE_REGISTRY_PRODUCTION}/" secret-namespace.sh
  sed -i "s/__ALI_IMAGE_USER__/${ALI_IMAGE_USER}/" secret-namespace.sh
  sed -i "s/__ALI_IMAGE_PASSWORD__/${ALI_IMAGE_PASSWORD}/" secret-namespace.sh
  sed -i "s/__NAMESPACE__/${NAMESPACE}/g" secret-namespace.sh
  cat secret-namespace.sh
  sh -x secret-namespace.sh
fi

kubectl get sc | grep -wq ${CI_PROJECT_NAME}
if [ $? -eq 0 ]; then
  echo "The Storageclass already exists and does not need to be created"
else
  ###storageclass
  echo "The storageclass does not exist and needs to be created"
  sed -i "s/__NAMESPACE__/${NAMESPACE}/g" storageclass/storage-class.yaml
  sed -i "s/__CI_PROJECT_NAME__/${CI_PROJECT_NAME}/g" storageclass/storage-class.yaml
  cat storageclass/storage-class.yaml
	kubectl apply -f storageclass/storage-class.yaml
fi

kubectl get pvc -n $NAMESPACE | grep -wq ${CI_PROJECT_NAME}
if [ $? -eq 0 ]; then
  echo "The Pvc already exists and does not need to be created"
else
  ###pvc
  echo "The Pvc does not exist and needs to be created"
  sed -i "s/__NAMESPACE__/${NAMESPACE}/g" storageclass/pvc.yaml
  sed -i "s/__CI_PROJECT_NAME__/${CI_PROJECT_NAME}/g" storageclass/pvc.yaml
  cat storageclass/pvc.yaml
	kubectl apply -f storageclass/pvc.yaml
fi

echo -e "\033[45;30m DEPLOYMENT \033[0m"
kubectl get deployment -n $NAMESPACE | grep -wq ${CI_PROJECT_NAME}
if [ $? -eq 0 ]; then
  echo "=> Patching deployment to force image update."
  kubectl patch -f deployment.yaml -p "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"ci-last-updated\":\"$(date +'%s')\"}}}}}"
  kubectl set image deployment ${CI_PROJECT_NAME} ${CI_PROJECT_NAME}=${REGISTRY_IMAGE}
else
  ###deployment
  sed -i "s/__NAMESPACE__/${NAMESPACE}/g" deployment.yaml
  sed -i "s/__CI_PROJECT_NAME__/${CI_PROJECT_NAME}/g"  deployment.yaml
  sed -i "s/__VERSION__/"${CI_COMMIT_REF_NAME//\//-}-$CI_PIPELINE_ID"/" deployment.yaml
  sed -i "s/__PORT__/${PORT}/g" deployment.yaml
  cat deployment.yaml
  kubectl apply -f deployment.yaml
fi

echo -e "\033[45;30m SERVICE \033[0m"
kubectl get service -n $NAMESPACE  | grep -wq ${CI_PROJECT_NAME}
if [ $? -eq 0 ]; then
  echo "Service already exists, no need to create it"
else
  ###svc
  echo "Service does not exist. It needs to be created"
  sed -i "s/__NAMESPACE__/${NAMESPACE}/g" svc.yaml
  sed -i "s/__PORT__/${PORT}/g" svc.yaml
  sed -i "s/__CI_PROJECT_NAME__/${CI_PROJECT_NAME}/g" svc.yaml
  cat svc.yaml
	kubectl apply -f svc.yaml
fi

echo -e "\033[45;30m INGRESS \033[0m"
kubectl get ingress -n $NAMESPACE  | grep -wq ${CI_PROJECT_NAME}
if [ $? -eq 0 ]; then
  echo "Ingress already exists, no need to create it"
else
  ###ingress
  echo "Ingress does not exist. It needs to be created"
  sed -i "s/__NAMESPACE__/${NAMESPACE}/g" ingress/${CI_COMMIT_REF_NAME//\//-}.yaml
  sed -i "s/__PORT__/${PORT}/g" ingress/${CI_COMMIT_REF_NAME//\//-}.yaml
  sed -i "s/__CI_PROJECT_NAME__/${CI_PROJECT_NAME}/g" ingress/${CI_COMMIT_REF_NAME//\//-}.yaml
  cat ingress/${CI_COMMIT_REF_NAME//\//-}.yaml
  kubectl apply -f ingress/${CI_COMMIT_REF_NAME//\//-}.yaml
fi

echo -e "\033[45;30m HPA \033[0m"
kubectl get hpa -n $NAMESPACE  | grep -wq ${CI_PROJECT_NAME}
if [ $? -eq 0 ]; then
  echo "HPA already exists, no need to create it"
else
  ###HPA
  echo "HPA does not exist. It needs to be created"
  sed -i "s/__NAMESPACE__/${NAMESPACE}/g" hpa.yaml
  sed -i "s/__CI_PROJECT_NAME__/${CI_PROJECT_NAME}/g" hpa.yaml
  cat hpa.yaml
  kubectl apply -f hpa.yaml
fi

echo -e "\033[45;30m Final resource allocation \033[0m"
kubectl rollout status -f deployment.yaml
kubectl get all -l name=${CI_PROJECT_NAME} -n ${NAMESPACE}
```

### CSI
![](https://cdn.nlark.com/yuque/0/2020/png/1143489/1601347704319-e5035f36-f475-4998-8bb6-ba0cd8e04027.png)

pvc.yaml
```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: __CI_PROJECT_NAME__
  namespace: __NAMESPACE__
spec:
  storageClassName: __CI_PROJECT_NAME__
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 2Gi   ##所需存储预估大小，可以修改
```
storage-class.yaml
```
##########################################################################
#Author:                     zisefeizhu
#QQ:                         2********0
#Date:                       2020-08-14
#FileName:                   storage-class.yaml
#URL:                        https://www.cnblogs.com/zisefeizhu/
#Description:                The test script
#Copyright (C):              2020 All rights reserved
###########################################################################
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: __CI_PROJECT_NAME__
  namespace: __NAMESPACE__     #这里的namespace 没啥用
mountOptions:
  - nolock,tcp,noresvport
  - vers=3
parameters:
  volumeAs: subpath
  server: "29afc4b600-mju20.cn-shenzhen.nas.aliyuncs.com:/stage/"    #挂载点
provisioner: nasplugin.csi.alibabacloud.com
reclaimPolicy: Retain
```

### flexvolume
pvc.yaml
```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: __CI_PROJECT_NAME__
  namespace: __NAMESPACE__
spec:
  storageClassName: __CI_PROJECT_NAME__
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 2Gi
```
storage-class.yaml
```
##########################################################################
#Author:                     zisefeizhu
#QQ:                         2********0
#Date:                       2020-08-14
#FileName:                   storage-class.yaml
#URL:                        https://www.cnblogs.com/zisefeizhu/
#Description:                The test script
#Copyright (C):              2020 All rights reserved
###########################################################################
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: __CI_PROJECT_NAME__
  namespace: __NAMESPACE__   
mountOptions:
  - nolock,tcp,noresvport
  - vers=3
parameters:
  driver: flexvolume
  server: "29afc4b600-mju20.cn-shenzhen.nas.aliyuncs.com:/stage/"  #挂载点
provisioner: alicloud/nas
reclaimPolicy: Delete
```
👌！至此存储考量 阐述完毕！

👌！至此整个集群的CI/CD 阐述完毕！




























