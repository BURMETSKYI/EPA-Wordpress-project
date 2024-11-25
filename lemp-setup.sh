#!/bin/bash
sudo apt-get update -y && sudo apt-get upgrade -y
sudo apt install git -y
git clone 
sudo apt install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx
sudo apt install mariadb-server -y
sudo systemctl start mariadb
sudo systemctl enable mariadb
sudo apt install php php-cli php-common php-imap php-fpm php-snmp php-xml php-zip php-mbstring php-curl php-mysqli php-gd php-intl
 
