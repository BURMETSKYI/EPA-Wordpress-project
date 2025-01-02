#!/bin/bash

# Constants
db_username=DB_USERNAME   # Replace with RDS admin username
db_password=DB_PASSWORD   # Replace with RDS admin password

cp /home/ubuntu/s3-epa/all_databases_backup.sql /tmp/

sudo systemctl status mariadb
sudo systemctl start mariadb

sudo mysql -u $db_username -p$db_password < /tmp/all_databases_backup.sql
