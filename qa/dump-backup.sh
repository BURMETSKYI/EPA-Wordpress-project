#!/bin/bash
set -euo pipefail

# Constants
rds_endpoint=RDS_ENDPOINT
db_username=DB_USERNAME
db_password=DB_PASSWORD
domain=DOMAIN
s_domain=S_DOMAIN
backup_file="/home/ubuntu/wp_backup.sql"

# Create backup
echo "Creating database backup..."
mysqldump -h "$rds_endpoint" \
-u "$db_username" \
-p"$db_password" \
--databases admin > "$backup_file"

# Set permissions
echo "Setting file permissions..."
sudo chmod 777 "$backup_file"
sudo chown ubuntu:ubuntu "$backup_file"

# Copy to S3 mount to dev
echo "Copying to S3 mount point..."
sudo cp "$backup_file" /home/ubuntu/s3-epa/dev/

# Replace URLs
echo "Replacing URLs in backup file..."
sudo sed -i 's|https://dev.moncorp.uk|https://prod1.moncorp.uk|g' /home/ubuntu/wp_backup.sql

sudo rm /home/ubuntu/s3-epa/wp_backup.sql

# Copy to S3 mount for prod
echo "Copying to S3 mount point..."
sudo cp "$backup_file" /home/ubuntu/s3-epa/

sudo rm $backup_file
                        
