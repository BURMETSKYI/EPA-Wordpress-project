#!/bin/bash
sudo apt -y install git
sudo git clone https://github.com/BURMETSKYI/EPA-Wordpress-project.git /root/EPA-Wordpress-project
sudo chmod -R 755 /root/EPA-Wordpress-project/
sudo bash /root/EPA-Wordpress-project/lemp-setup.sh > /root/test.txt
