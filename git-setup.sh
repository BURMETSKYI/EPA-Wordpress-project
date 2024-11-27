#!/bin/bash
sudo apt -y install git
sudo git clone https://github.com/BURMETSKYI/EPA-Wordpress-project.git /root
sudo chmod -R 755 /EPA-Wordpress-project/
sudo bash /EPA-Wordpress-project/lemp-setup.sh
