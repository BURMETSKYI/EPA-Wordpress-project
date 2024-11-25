#!/bin/bash
sudo apt -y install git
cd /root/
sudo git clone https://github.com/BURMETSKYI/EPA-Wordpress-project.git
chmod -R 755 /EPA-Wordpress-project/
sudo bash /EPA-Wordpress-project/lemp-setup.sh
