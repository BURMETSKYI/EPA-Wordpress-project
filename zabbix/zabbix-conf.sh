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

# Clear the log file
> $LOG_FILE

# Zabbix server configuration file path
ZABBIX_CONF="/etc/zabbix/zabbix_server.conf"

# Update Zabbix server configuration
echo "Updating Zabbix server configuration..." | tee -a $LOG_FILE

# Set WebDriverURL
sudo sed -i "s|^# WebDriverURL=.*|WebDriverURL=http://localhost:4444|" $ZABBIX_CONF
check_exit_status "Set WebDriverURL in Zabbix server configuration"

# Set StartBrowserPollers
sudo sed -i "s|^# StartBrowserPollers=.*|StartBrowserPollers=5|" $ZABBIX_CONF
check_exit_status "Set StartBrowserPollers in Zabbix server configuration"

# Restart Zabbix server service
echo "Restarting Zabbix server..." | tee -a $LOG_FILE
sudo systemctl restart zabbix-server
check_exit_status "Zabbix server restart"

# Output completion message
echo "Zabbix server configuration updated and restarted successfully!" | tee -a $LOG_FILE
