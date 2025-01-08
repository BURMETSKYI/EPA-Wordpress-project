#!/bin/bash

# Log file path
LOG_FILE="/var/log/zabbix-setup.log"

# Function to check the exit status of the last executed command
check_exit_status() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed." | tee -a $LOG_FILE
        exit 1
    else
        echo "$1 succeeded." | tee -a $LOG_FILE
    fi
}

# Clear the log file at the beginning of the script
> $LOG_FILE

# Variables
DB_PASSWORD=ZABBIX_DB

# Update and upgrade system packages
echo "Updating package lists..." | tee -a $LOG_FILE
sudo apt-get update -y
check_exit_status "apt-get update"

echo "Upgrading installed packages..." | tee -a $LOG_FILE
sudo apt-get upgrade -y
check_exit_status "apt-get upgrade"

# Install Apache and PHP dependencies
echo "Installing Apache and PHP..." | tee -a $LOG_FILE
sudo apt-get install -y apache2 php php-{cgi,common,mbstring,net-socket,gd,xml-util,mysql,bcmath,imap,snmp} libapache2-mod-php
check_exit_status "Apache and PHP installation"

# Install MySQL server
echo "Installing MySQL server..." | tee -a $LOG_FILE
sudo apt-get install -y mysql-server
check_exit_status "MySQL server installation"

# Add Zabbix repository and install Zabbix components
echo "Downloading and installing Zabbix repository..." | tee -a $LOG_FILE
sudo wget -q https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.0+ubuntu24.04_all.deb
sudo dpkg -i zabbix-release_latest_7.0+ubuntu24.04_all.deb
check_exit_status "Zabbix repository setup"

echo "Updating package lists after adding Zabbix repo..." | tee -a $LOG_FILE
sudo apt-get update -y
check_exit_status "apt-get update (Zabbix repo)"

echo "Installing Zabbix server, frontend, and agent..." | tee -a $LOG_FILE
sudo apt-get install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent
check_exit_status "Zabbix installation"

# Configure MySQL for Zabbix
echo "Configuring MySQL for Zabbix..." | tee -a $LOG_FILE

DB_EXISTS=$(sudo mysql -e "SHOW DATABASES LIKE 'zabbix';" | grep -c "zabbix")

if [ "$DB_EXISTS" -eq 0 ]; then
    echo "Creating Zabbix database..." | tee -a $LOG_FILE
    sudo mysql -e "CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;"
    check_exit_status "Database creation"
else
    echo "Database 'zabbix' already exists. Skipping database creation." | tee -a $LOG_FILE
fi

USER_EXISTS=$(sudo mysql -e "SELECT User FROM mysql.user WHERE User = 'zabbix';" | grep -c "zabbix")

if [ "$USER_EXISTS" -eq 0 ]; then
    echo "Creating Zabbix user..." | tee -a $LOG_FILE
    sudo mysql -e "CREATE USER 'zabbix'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';"
    check_exit_status "User creation"
else
    echo "User 'zabbix' already exists. Skipping user creation." | tee -a $LOG_FILE
fi

echo "Granting privileges to Zabbix user..." | tee -a $LOG_FILE
sudo mysql -e "GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';"
check_exit_status "Grant privileges"

echo "Setting global log_bin_trust_function_creators..." | tee -a $LOG_FILE
sudo mysql -e "SET GLOBAL log_bin_trust_function_creators = 1;"
check_exit_status "Log bin trust function setting"

# Import initial schema and data
echo "Importing Zabbix schema and data..." | tee -a $LOG_FILE
sudo zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -p"${DB_PASSWORD}" zabbix
check_exit_status "Schema import"

# Disable log_bin_trust_function_creators
echo "Disabling log_bin_trust_function_creators..." | tee -a $LOG_FILE
sudo mysql -e "SET GLOBAL log_bin_trust_function_creators = 0;"
check_exit_status "Disable log_bin_trust_function_creators"

# Configure Zabbix server
echo "Configuring Zabbix server..." | tee -a $LOG_FILE
sudo sed -i "s/^# DBPassword=.*/DBPassword=${DB_PASSWORD}/" /etc/zabbix/zabbix_server.conf
check_exit_status "Zabbix server configuration"

# Start and enable Zabbix services
echo "Starting and enabling Zabbix services..." | tee -a $LOG_FILE
sudo systemctl restart zabbix-server zabbix-agent apache2
sudo systemctl enable zabbix-server zabbix-agent apache2
check_exit_status "Zabbix services"

# Output completion message
echo "Zabbix setup completed successfully!" | tee -a $LOG_FILE
