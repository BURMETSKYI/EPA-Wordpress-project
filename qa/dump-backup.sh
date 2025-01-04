#!/bin/bash
set -euo pipefail

# Constants
rds_endpoint=RDS_ENDPOINT
db_username=DB_USERNAME
db_password=DB_PASSWORD
domain=DOMAIN
s_domain=S_DOMAIN
backup_file="/home/ubuntu/"

# Create backup
echo "Creating database backup..."
mysqldump -h "$rds_endpoint" \
-u "$db_username" \
-p"$db_password" \
--databases admin > "$backup_file/wp_backup.sql"

# Set permissions
echo "Setting file permissions..."
sudo chmod 644 "$backup_file"
sudo chown ubuntu:ubuntu "$backup_file"

# Copy to S3 mount to dev
echo "Copying to S3 mount point..."
sudo cp "$backup_file/wp_backup.sql" /home/ubuntu/s3-epa/dev/wp_backup_$domain.sql

# Replace URLs
echo "Replacing URLs in backup file..."
sed -i 's|https://$domain|https://$s_domain|g' "$backup_file/wp_backup.sql"

# Copy to S3 mount for prod
echo "Copying to S3 mount point..."
sudo cp "$backup_file/wp_backup.sql" /home/ubuntu/s3-epa/wp_backup_$s_domain.sql

sudo rm $backup_file

echo "Backup process completed successfully!"
