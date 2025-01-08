#!/bin/bash

# Log file path
LOG_FILE="/var/log/zabbix-setup.log"
ZABBIX_IP=S_ZABBIX_IP # Replace ZABBIX_IP with the actual IP address of the Zabbix server
HOSTNAME=CLIENT_HOSTNAME

# Function to check the exit status of the last executed command
check_exit_status() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed." | tee -a $LOG_FILE
        exit 1
    else
        echo "$1 succeeded." | tee -a $LOG_FILE
    fi
}

# Clear the log file
> $LOG_FILE

# Install Zabbix agent
echo "Installing Zabbix agent..." | tee -a $LOG_FILE
sudo wget -q https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.0+ubuntu24.04_all.deb
sudo dpkg -i zabbix-release_latest_7.0+ubuntu24.04_all.deb
sudo apt update -y
sudo apt install -y zabbix-agent
check_exit_status "Zabbix agent installation"

# Update Zabbix agent configuration
echo "Configuring Zabbix agent..." | tee -a $LOG_FILE
CONFIG_FILE="/etc/zabbix/zabbix_agentd.conf"

# Update 'Server' parameter
sudo sed -i "s|^Server=.*|Server=${ZABBIX_IP}|" $CONFIG_FILE
check_exit_status "Set Server in configuration"

# Update 'ServerActive' parameter
sudo sed -i "s|^ServerActive=.*|ServerActive=${ZABBIX_IP}|" $CONFIG_FILE
check_exit_status "Set ServerActive in configuration"

# Update 'Hostname' parameter
sudo sed -i "s|^Hostname=.*|Hostname=${HOSTNAME}|" $CONFIG_FILE
check_exit_status "Set Hostname in configuration"

# Restart Zabbix agent service
echo "Restarting Zabbix agent..." | tee -a $LOG_FILE
sudo systemctl restart zabbix-agent
check_exit_status "Zabbix agent restart"

# Check Zabbix agent status
echo "Checking Zabbix agent status..." | tee -a $LOG_FILE
sudo systemctl status zabbix-agent | tee -a $LOG_FILE

# Completion message
echo "Zabbix agent setup completed successfully!" | tee -a $LOG_FILE
