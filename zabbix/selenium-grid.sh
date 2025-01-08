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

sudo wget https://raw.githubusercontent.com/SeleniumHQ/docker-selenium/trunk/docker-compose-v3-full-grid.yml -O docker-compose.yml

sudo docker compose up -d
