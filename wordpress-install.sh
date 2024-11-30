#!/bin/bash
sudo rm -rf /var/www/html
sudo apt -y install unzip
sudo wget -O /var/www/latest.zip https://wordpress.org/latest.zip
sudo unzip /var/www/latest.zip -d /var/www
sudo rm /var/www/latest.zip
sudo mv /var/www/wordpress /var/www/html

# Generate username and password for MariaDB
password=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 25)
username=$(tr -dc 'A-Za-z' < /dev/urandom | head -c 25)

echo $password > creds.txt
echo $username >> creds.txt

sudo mysql -e "CREATE DATABASE IF NOT EXISTS $username"
sudo mysql -e "CREATE USER '$username'@'localhost' IDENTIFIED BY '$password'"
sudo mysql -e "GRANT ALL PRIVILEGES ON $username.* TO '$username'@'localhost'"
sudo mysql -e "FLUSH PRIVILEGES"

# sudo wget -O /var/www/html/wp-config.php https://wp-s3-storage.s3.us-east-1.amazonaws.com/wp-config.php
sudo chmod 640 /var/www/html/wp-config.php 
sudo chown -R www-data:www-data /var/www/html

sed -i 's/password_here/$password/g' /var/www/html/wp-config.php
sed -i "s/username_here/$username/g" /var/www/html/wp-config.php
sed -i "s/database_name_here/$username/g" /var/www/html/wp-config.php
