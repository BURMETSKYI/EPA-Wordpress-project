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

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# Update package lists
echo "Updating package lists..." | tee -a $LOG_FILE
sudo apt-get update -y
check_exit_status "apt-get update"

# Install Docker Compose plugin
echo "Installing Docker Compose plugin..." | tee -a $LOG_FILE
sudo apt-get install -y docker-compose-plugin
check_exit_status "Docker Compose plugin installation"

# Verify Docker Compose installation
echo "Verifying Docker Compose installation..." | tee -a $LOG_FILE
docker compose version | tee -a $LOG_FILE
check_exit_status "Docker Compose version check"
