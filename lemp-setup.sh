#!/bin/bash
sudo apt install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx
sudo systemctl status nginx >> nginx_mariadb_php_test.txt
sudo apt install mariadb-server -y
sudo systemctl start mariadb
sudo systemctl enable mariadb
sudo systemctl status mariadb >> nginx_mariadb_php_test.txt
sudo apt -y install php php-cli php-common php-imap php-fpm php-snmp php-xml php-zip php-mbstring php-curl php-mysqli php-gd php-intl
sudo php -v >> /root/nginx_mariadb_php_test.txt
sudo systemctl stop apache2
sudo systemctl disable apache2
sudo mv /var/www/html/index.html /var/www/html/index.html.old
sudo mv /root/EPA-Wordpress-project/nginx.conf /etc/nginx/conf.d/nginx.conf

# dns_record=$(curl -s icanhazip.com | sed 's/^/ec2-/; s/\./-/g; s/$/.compute-1.amazonaws.com/')
domain= S_DOMAIN
elastic_ip= S_ELASTIC_IP

CF_API= S_CF_API
CF_ZONE_ID= S_CF_ZONE_ID

curl --request POST \
  --url https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer $CF_API" \
  --data '{
  "content": "'"$elastic_ip"'",
  "name": "'"$domain"'",
  "proxied": true,
  "type": "A",
  "comment": "Automatically adding A record",
  "tags": [],
  "ttl": 3600
}'

sed -i "s/SERVERNAME/$domain/g" /etc/nginx/conf.d/nginx.conf
nginx -t && systemctl reload nginx
sudo bash /root/EPA-Wordpress-project/certbot-ssl-install.sh
