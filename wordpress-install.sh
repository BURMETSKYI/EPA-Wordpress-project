#!/bin/bash
sudo rm -rf /var/www/html
sudo apt -y install unzip
sudo wget -O /var/www/latest.zip https://wordpress.org/latest.zip
sudo unzip /var/www/latest.zip
sudo rm /var/www/latest.zip
sudo mv /var/www/wordpress /var/www/html
sudo mysql -e "CREATE DATABASE IF NO EXISTS wordpress"
sudo mysql -e "CREATE USER wpuser@localhost identified by 'password'"
sudo mysql -e "GRANT ALL PRIVILEGES ON wordpress.* to wpuser@localhost"
sudo mysql -e "FLUSH PRIVILEGES"
sudo cd /var/www/html/wordpress
sudo wget -O /var/www/html/wp-config.php https://wp-s3-storage.s3.us-east-1.amazonaws.com/wp-config.php
sudo chmod 640 /var/www/html/wp-config.php 
sudo chown -R www-data:www-data /var/www/html
