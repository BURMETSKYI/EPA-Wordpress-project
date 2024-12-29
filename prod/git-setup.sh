#!/bin/bash

# Log file path
LOG_FILE="/var/log/git-setup.log"

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

# sudo apt update
echo "Running apt update..." | tee -a $LOG_FILE
sudo apt-get update -y
check_exit_status "apt update"

# sudo apt upgrade
echo "Running apt upgrade..." | tee -a $LOG_FILE
sudo apt-get upgrade -y
check_exit_status "apt upgrade"

# git clone repository
# echo "Cloning GitHub repository..." | tee -a $LOG_FILE
#sudo git clone https://github.com/BURMETSKYI/EPA-Wordpress-project.git /root/EPA-Wordpress-project
# check_exit_status "git clone"

# sudo chmod 
echo "Changing permissions of the cloned repository..." | tee -a $LOG_FILE
sudo chmod -R 755 /home/ubuntu/EPA-Wordpress-project/
check_exit_status "chmod"

sudo touch /home/ubuntu/nginx_mariadb_php_test.txt # Unit tests log file
echo "Unit test log file created..." | tee -a $LOG_FILE

# lemp-setup.sh
# echo "Running lemp-setup.sh script..." | tee -a $LOG_FILE
# sudo bash /root/EPA-Wordpress-project/lemp-setup.sh
# check_exit_status "lemp-setup.sh script"
