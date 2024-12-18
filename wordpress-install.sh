#!/bin/bash

# Constants
rds_edpoint=RDS_ENDPOINT  # Replace with RDS endpoint
db_username=DB_USERNAME   # Replace with RDS admin username
db_password=DB_PASSWORD   # Replace with RDS admin password
storage_url=STORAGE_URL   # Replace with persistent storage url

# Functions for error handling
function check_exit_status {
    if [ $? -ne 0 ]; then
        echo "$1 failed. Exiting."
        exit 1
    fi
}

# Install mariadb-client
echo "Installing required packages..."
sudo apt update
sudo apt -y install unzip wget mariadb-client
check_exit_status "Package installation"

# Remove any existing WordPress installation
echo "Cleaning up existing WordPress installation..."
sudo rm -rf /var/www/html

# Download and extract the latest WordPress package
echo "Downloading the latest WordPress..."
sudo wget -O /var/www/latest.zip https://wordpress.org/latest.zip
check_exit_status "WordPress download"

echo "Extracting WordPress files..."
sudo unzip /var/www/latest.zip -d /var/www
check_exit_status "WordPress extraction"

# Move WordPress to the correct location
echo "Setting up WordPress directory..."
sudo mv /var/www/wordpress /var/www/html
sudo rm /var/www/latest.zip
check_exit_status "WordPress setup"

# Create or connect to existing database in RDS
echo "Creating database '$db_username' on RDS..."
mysql -h $rds_edpoint -u $db_username -p$db_password -e "CREATE DATABASE IF NOT EXISTS $db_username;"
check_exit_status "Database creation"

# Set up wp-config.php
echo "Configuring WordPress..."
sudo mv /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
sudo sed -i "s/database_name_here/$db_username/g" /var/www/html/wp-config.php
sudo sed -i "s/username_here/$db_username/g" /var/www/html/wp-config.php
sudo sed -i "s/password_here/$db_password/g" /var/www/html/wp-config.php
sudo sed -i "s/localhost/$rds_edpoint/g" /var/www/html/wp-config.php

# Secure the wp-config.php file
echo "Securing WordPress configuration..."
sudo chmod 640 /var/www/html/wp-config.php
sudo chown -R www-data:www-data /var/www/html
check_exit_status "WordPress configuration security"

echo "WordPress setup is complete. You can now visit your site."

# S3fuse mount of persistent content storage  
mkdir -p /home/ubuntu/s3-epa
sudo chown ubuntu:ubuntu /home/ubuntu/s3-epa
sudo chmod 755 /home/ubuntu/s3-epa
sudo apt install s3fs
sudo sed -i 's/^#user_allow_other/user_allow_other/' /etc/fuse.conf
s3fs s3-epa /home/ubuntu/s3-epa -o iam_role=auto -o endpoint=eu-west-2 -o url= -o allow_other -o use_path_request_style -o nonempty

