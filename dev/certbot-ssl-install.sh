#!/bin/bash

# Update package list and install Certbot and Certbot Nginx plugin
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y certbot python3-certbot-nginx

# Define your email
EMAIL=S_EMAIL
DOMAIN=S_DOMAIN

# Use Certbot to obtain and install the SSL certificate
sudo certbot --nginx --non-interactive --agree-tos --email $EMAIL -d $DOMAIN

# Nginx unit test that will reload Nginx to apply changes ONLY if the test is successful
sudo nginx -t && systemctl reload nginx

# command to test the installation of new certs. You can only install 50 per week per domain.
# sudo certbot renew --dry-run

# RUN Wordpress installation script
# sudo bash /root/EPA-Wordpress-project/wordpress-install.sh
