#!/bin/bash
set -euo pipefail

# Constants
storage_url="wp-green.cfk4aya0a4fd.eu-west-2.rds.amazonaws.com"
db_username="admin"
db_password="Ujinsoap1322"
backup_file="/home/ubuntu/wp_backup.sql"

# Create backup
echo "Creating database backup..."
mysqldump -h "$storage_url" \
-u "$db_username" \
-p"$db_password" \
--databases admin > "$backup_file"

# Set permissions
echo "Setting file permissions..."
sudo chmod 644 "$backup_file"
sudo chown ubuntu:ubuntu "$backup_file"

# Replace URLs
echo "Replacing URLs in backup file..."
sed -i 's|https://dev.moncorp.uk|https://test.moncorp.uk|g' "$backup_file"

# Copy to S3 mount
echo "Copying to S3 mount point..."
sudo cp "$backup_file" /home/ubuntu/s3-epa/

echo "Backup process completed successfully!"
