#!/bin/bash
sudo apt install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx
sudo systemctl status nginx >> /root/test.txt
sudo apt install mariadb-server -y
sudo systemctl start mariadb
sudo systemctl enable mariadb
sudo systemctl status mariadb >> /root/test.txt
sudo apt -y install php php-cli php-common php-imap php-fpm php-snmp php-xml php-zip php-mbstring php-curl php-mysqli php-gd php-intl
sudo php -v >> /root/test.txt
sudo mv /var/www/html/index.html /var/www/html/index.html.old
sudo bash /root/EPA-Wordpress-project/wordpress-install.sh >> /root/test.txt
