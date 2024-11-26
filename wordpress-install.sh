#!/bin/bash
sudo cd /var/www/
sudo rm -rf html
sudo apt -y install unzip
sudo wget https://wordpress.org/latest.zip
sudo mkdir -p /usr/share/nginx
sudo unzip latest.zip
sudo mv wordpress html
sudo rm latest.zip
sudo mariadb -u root
sudo mysql -e "CREATE DATABASE IF NO EXISTS wordpress"
sudo mysql -e "CREATE USER wpuser@localhost identified by 'password'"
sudo mysql -e "GRANT ALL PRIVILEGES ON wordpress.* to wpuser@localhost"
sudo mysql -e "FLUSH PRIVILEGES"
sudo cd /var/www/html
sudo wget https://wp-s3-storage.s3.us-east-1.amazonaws.com/wp-config.php
sudo chmod 640 wp-config.php 
sudo chown -R www-data:www-data /var/www/html
