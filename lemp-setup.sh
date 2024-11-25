#!/bin/bash
sudo apt-get update -y
sudo apt-get upgrade -y
sudo touch test.txt # Unit tests log file for LEMP
sudo apt install git -y
sudo apt install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx
sudo systemctl status nginx > test.txt
sudo apt install mariadb-server -y
sudo systemctl start mariadb
sudo systemctl enable mariadb
sudo systemctl status mariadb >> test.txt
sudo apt -y install php php-cli php-common php-imap php-fpm php-snmp php-xml php-zip php-mbstring php-curl php-mysqli php-gd php-intl
sudo php -v >> test.txt
