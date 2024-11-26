#!/bin/bash
sudo cd /var/www/html
sudo apt -y install unzip
sudo wget https://wordpress.org/latest.zip
sudo mkdir -p /usr/share/nginx
sudo unzip latest.zip
sudo rm latest.zip
sudo mariadb -u root
