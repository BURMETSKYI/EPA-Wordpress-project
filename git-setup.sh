#!/bin/bash
sudo apt-get update -y
sudo apt-get upgrade -y
sudo git clone https://github.com/BURMETSKYI/EPA-Wordpress-project.git /root/EPA-Wordpress-project
sudo chmod -R 755 /root/EPA-Wordpress-project/
sudo touch /root/test.txt # Unit tests log file
sudo bash /root/EPA-Wordpress-project/lemp-setup.sh >> /root/test.txt
