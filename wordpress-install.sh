#!/bin/bash

# Remove existing WordPress installation (if any)
sudo rm -rf /var/www/html

# Install unzip if not installed
sudo apt -y install unzip

# Download the latest WordPress zip file
sudo wget -O /var/www/latest.zip https://wordpress.org/latest.zip

# Unzip WordPress into the correct directory
sudo unzip /var/www/latest.zip -d /var/www

# Remove the downloaded zip file to clean up
sudo rm /var/www/latest.zip

# Move WordPress files into the correct directory
sudo mv /var/www/wordpress /var/www/html

# Generate a random username and password for MariaDB
password=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 25)
username=$(tr -dc 'A-Za-z' < /dev/urandom | head -c 25)

# Store the credentials in creds.txt
echo $password > creds.txt
echo $username >> creds.txt

# Create the database and user in MariaDB
sudo mysql -e "CREATE DATABASE IF NOT EXISTS '$username'"
if [ $? -eq 0 ]; then
    echo "Database $username created or already exists."
else
    echo "Failed to create database."
    exit 1
fi

# Create the user and set the password
sudo mysql -e "CREATE USER '$username'@'localhost' IDENTIFIED BY '$password'"
if [ $? -eq 0 ]; then
    echo "User $username created successfully."
else
    echo "Failed to create user."
    exit 1
fi

# Grant the user full privileges on their database
sudo mysql -e "GRANT ALL PRIVILEGES ON $username.* TO '$username'@'localhost'"
if [ $? -eq 0 ]; then
    echo "Privileges granted to $username."
else
    echo "Failed to grant privileges."
    exit 1
fi

# Flush privileges to apply the changes
sudo mysql -e "FLUSH PRIVILEGES"
if [ $? -eq 0 ]; then
    echo "Privileges flushed successfully."
else
    echo "Failed to flush privileges."
    exit 1
fi

echo "Database and user setup completed successfully."

# sudo wget -O /var/www/html/wp-config.php https://wp-s3-storage.s3.us-east-1.amazonaws.com/wp-config.php

# Move the sample wp-config file to wp-config.php
sudo mv /var/www/html/wp-config-sample.php /var/www/html/wp-config.php

# Secure the wp-config.php file with proper permissions
sudo chmod 640 /var/www/html/wp-config.php 
sudo chown -R www-data:www-data /var/www/html

# Replace placeholder values with actual credentials in wp-config.php
sudo sed -i "s/password_here/$password/g" /var/www/html/wp-config.php
sudo sed -i "s/username_here/$username/g" /var/www/html/wp-config.php
sudo sed -i "s/database_name_here/$username/g" /var/www/html/wp-config.php

echo "WordPress configuration completed. You can now visit your site."

