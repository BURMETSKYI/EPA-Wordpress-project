#!/bin/bash

# Install Nginx web server
sudo apt install nginx -y

# Start Nginx service
sudo systemctl start nginx

# Enable Nginx service to start on boot
sudo systemctl enable nginx

# Enable Nginx service to start on boot
sudo systemctl status nginx >> nginx_mariadb_php_test.txt

# Install PHP and required PHP modules for a LEMP stack (Linux, Nginx, MariaDB, PHP)
sudo apt -y install php php-cli php-common php-imap php-fpm php-snmp php-xml php-zip php-mbstring php-curl php-mysqli php-gd php-intl

# Verify PHP installation by logging its version into a file
sudo php -v >> /root/nginx_mariadb_php_test.txt

# Stop Apache2 service if running (it’s not needed in a LEMP stack)
sudo systemctl stop apache2

# Disable Apache2 service to prevent it from starting on boot
sudo systemctl disable apache2

# Move custom Nginx configuration file to the correct directory for it to be used
sudo mv /home/ubuntu/EPA-Wordpress-project/nginx.conf /etc/nginx/conf.d/nginx.conf

# Set variables for domain
domain=S_DOMAIN

# Replace placeholder SERVERNAME with the actual domain in the Nginx configuration file
sudo sed -i "s/SERVERNAME/$domain/g" /etc/nginx/conf.d/nginx.conf

# Test the Nginx configuration for syntax errors and reload the Nginx service if successful
nginx -t && systemctl reload nginx
