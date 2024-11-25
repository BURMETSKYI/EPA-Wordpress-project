#!/bin/bash
sudo apt-get update -y && sudo apt-get upgrade -y
sudo apt install nginx -y
systemctl start nginx
systemctl enable nginx
