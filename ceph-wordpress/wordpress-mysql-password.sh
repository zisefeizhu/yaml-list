##########################################################################
#Author:                     zisefeizhu
#QQ:                         2********0
#Date:                       2020-09-12
#FileName:                   wordpress-mysql-password.sh
#URL:                        https://www.cnblogs.com/zisefeizhu/
#Description:                The test script
#Copyright (C):              2020 All rights reserved
##########################################################################
#!/bin/bash
kubectl -n myweb create secret generic mysql-pass --from-literal=password=zisefeizhu
