##  grep -Ev "^$|^[#;]" /etc/gitlab/gitlab.rb
#域名
external_url 'https://gitlab.realibox.cn'
#备份
gitlab_rails['backup_path'] = "/backups"
gitlab_rails['backup_archive_permissions'] = 0644
gitlab_rails['backup_keep_time'] = 604800
#ssl
nginx['enable'] = true
nginx['redirect_http_to_https_port'] = 80
nginx['ssl_certificate'] = "/etc/gitlab/ssl/server.crt"
nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/server.key"
#邮件发送
gitlab_rails['smtp_enable']=true
gitlab_rails['smtp_address']="smtp.exmail.qq.com"
gitlab_rails['smtp_port']=465
gitlab_rails['smtp_user_name']="noreply@realibox.com"
gitlab_rails['smtp_password']="Yinlibo2019"
gitlab_rails['smtp_domain']="realibox.com"
gitlab_rails['smtp_authentication']="login"
gitlab_rails['smtp_enable_starttls_auto']=true
gitlab_rails['smtp_tls']=true
gitlab_rails['gitlab_email_from']="noreply@realibox.com"