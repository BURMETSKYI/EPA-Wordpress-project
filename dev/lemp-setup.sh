#!/bin/bash

# Install Nginx web server
sudo apt install nginx -y

# Start Nginx service
sudo systemctl start nginx

# Enable Nginx service to start on boot
sudo systemctl enable nginx

# Enable Nginx service to start on boot
sudo systemctl status nginx >> nginx_mariadb_php_test.txt

# Install MariaDB server (MySQL-compatible database)
# sudo apt install mariadb-server -y

# Start MariaDB service
# sudo systemctl start mariadb


# Enable MariaDB service to start on boot
# sudo systemctl enable mariadb

# Check the status of MariaDB and log it into a file for reference
sudo systemctl status mariadb >> nginx_mariadb_php_test.txt

# Install PHP and required PHP modules for a LEMP stack (Linux, Nginx, MariaDB, PHP)
sudo apt -y install php php-cli php-common php-imap php-fpm php-snmp php-xml php-zip php-mbstring php-curl php-mysqli php-gd php-intl

# Verify PHP installation by logging its version into a file
sudo php -v >> /root/nginx_mariadb_php_test.txt

# Stop Apache2 service if running (it’s not needed in a LEMP stack)
sudo systemctl stop apache2

# Disable Apache2 service to prevent it from starting on boot
sudo systemctl disable apache2

# Optional: Move the default index.html for Nginx (commented out for now)
# sudo mv /var/www/html/index.html /var/www/html/index.html.old

# Move custom Nginx configuration file to the correct directory for it to be used
sudo mv /home/ubuntu/EPA-Wordpress-project/dev/nginx.conf /etc/nginx/conf.d/nginx.conf

# dns_record=$(curl -s icanhazip.com | sed 's/^/ec2-/; s/\./-/g; s/$/.compute-1.amazonaws.com/')

# Set variables for domain, Elastic IP, and Cloudflare API details (replace with actual values)
domain=S_DOMAIN
elastic_ip=S_ELASTIC_IP
CF_API=S_CF_API
CF_ZONE_ID=S_CF_ZONE_ID

# Use Cloudflare API to create a DNS A record for the domain pointing to the Elastic IP
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

# Replace placeholder SERVERNAME with the actual domain in the Nginx configuration file
sudo sed -i "s/SERVERNAME/$domain/g" /etc/nginx/conf.d/nginx.conf

# Test the Nginx configuration for syntax errors and reload the Nginx service if successful
nginx -t && systemctl reload nginx
