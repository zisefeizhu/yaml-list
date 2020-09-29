## 前提

服务器：39.108.252.175

密码：我不告诉你

CentOS Linux release 7.8.2003 (Core)

gitlab-ce-13.1.4-ce.0.el7.x86_64

## 主要配置文件

默认配置文件路径：/etc/gitlab

`/etc/gitlab/gitlab.rb`：主配置文件，包含外部URL、仓库目录、备份目录等

`/etc/gitlab/gitlab-secrets.json`：（执行gitlab-ctl reconfigure命令行后生成），包含各类密钥的加密信息

## 设置备份

```
# cat /etc/gitlab/gitlab.rb |grep -v "#" |grep -Ev '^$'
gitlab_rails['backup_path'] = "/backups"    #备份的目录
gitlab_rails['backup_archive_permissions'] = 0644  #备份包（tar格式压缩包）的权限
gitlab_rails['backup_keep_time'] = 604800  #备份的保留时间，单位是秒  7天【随便搞个吧 反正是全量备份】

# gitlab-ctl reconfigure  #重载配置，使之生效
```

### 挂载nas

无脑抄就妥了

![image.png](https://cdn.nlark.com/yuque/0/2020/png/1143489/1597475148504-b362b571-ca16-4a55-a819-9855c34a0046.png)

```
# sudo echo "options sunrpc tcp_slot_table_entries=128" >> /etc/modprobe.d/sunrpc.conf
# sudo echo "options sunrpc tcp_max_slot_table_entries=128" >> /etc/modprobe.d/sunrpc.conf
# mount -t nfs -o vers=3,nolock,proto=tcp,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport 29afc4b600-mju20.cn-shenzhen.nas.aliyuncs.com:/ /backups

# df -h | grep aliyun
29afxxx-mjxxx-shenzhen.nas.aliyuncs.com:/   10P  3.0M   10P   1% /backups

# cd /backups/ && ll
```

### 执行备份指令

```
#  gitlab-rake gitlab:backup:create
# ll
total 569582
-rw-r--r--  1 git  git  583249920 Aug 15 14:33 1597473194_2020_08_15_13.1.4_gitlab_backup.tar
# df -h | grep aliyun
29afc4b600-mju20.cn-shenzhen.nas.aliyuncs.com:/   10P  560M   10P   1% /backups
```

## 测试

```
[root@gitlab backups]# ll
total 569582
-rw-r--r--  1 git  git  583249920 Aug 15 14:57 1597474617_2020_08_15_13.1.4_gitlab_backup.tar
[root@gitlab backups]# cd ..
[root@gitlab /]# umount /backups
[root@gitlab /]# cd /backups/
[root@gitlab backups]# ll
total 0
[root@gitlab backups]# cd ..
[root@gitlab /]# mount -t nfs -o vers=3,nolock,proto=tcp,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport 29axxxxxxxx0.cn-shenzhen.nas.aliyuncs.com:/ /backups
[root@gitlab /]# cd /backups/
[root@gitlab backups]# ll
total 569582
-rw-r--r--  1 git  git  583249920 Aug 15 14:57 1597474617_2020_08_15_13.1.4_gitlab_backup.tar
```

## 定时备份

```
# crontab -l
# backup gitlab to nas 29afc4b600
0 2 * * * /usr/bin/gitlab-rake gitlab:backup:create
[root@gitlab backups]# systemctl restart crond.service 
```

## 还原数据

特别注意：

- 备份目录和gitlab.rb中定义的备份目录必须一致
- GitLab的版本和备份文件中的版本必须一致，否则还原时会报错。
```
# cat /etc/gitlab/gitlab.rb |grep "backup_path" |grep -Ev "^$"  # 确认备份目录
gitlab_rails['backup_path'] = "/backups"
# ll /backups/ # 确认备份文件
total 569582
-rw-r--r--  1 git  git  583249920 Aug 15 14:57 1597474617_2020_08_15_13.1.4_gitlab_backup.tar
# gitlab-rake gitlab:backup:restore BACKUP=1597474617_2020_08_15_13.1.4  # 还原
Unpacking backup ... done
Before restoring the database, we will remove all existing
tables to avoid future upgrade problems. Be aware that if you have
custom tables in the GitLab database these tables and all data will be
removed.

Do you want to continue (yes/no)? yes
Removing all tables. Press `Ctrl-C` within 5 seconds to abort
You will lose any data stored in the authorized_keys file.
Do you want to continue (yes/no)? yes
Warning: Your gitlab.rb and gitlab-secrets.json files contain sensitive data 
and are not included in this backup. You will need to restore these files manually.
Restore task is done.
# gitlab-ctl restart  # 重启服务
ok: run: alertmanager: (pid 26150) 1s
ok: run: gitaly: (pid 26163) 0s
ok: run: gitlab-exporter: (pid 26182) 1s
ok: run: gitlab-workhorse: (pid 26184) 0s
ok: run: grafana: (pid 26204) 1s
ok: run: logrotate: (pid 26216) 0s
ok: run: nginx: (pid 26223) 1s
ok: run: node-exporter: (pid 26229) 0s
ok: run: postgres-exporter: (pid 26235) 0s
ok: run: postgresql: (pid 26321) 1s
ok: run: prometheus: (pid 26330) 0s
ok: run: redis: (pid 26341) 1s
ok: run: redis-exporter: (pid 26345) 0s
ok: run: sidekiq: (pid 26353) 0s
ok: run: unicorn: (pid 26364) 0s
# gitlab-rake gitlab:check SANITZE=true  # 检查GitLab所有组件是否运行正常
```
备份策略：7天一循环，目录：/backups
