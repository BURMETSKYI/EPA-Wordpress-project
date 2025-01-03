#!/bin/bash
set -euo pipefail

# Constants
rds_endpoint=RDS_ENDPOINT
db_username=DB_USERNAME
db_password=DB_PASSWORD
backup_file="/home/ubuntu/wp_backup.sql"

# Create backup
echo "Creating database backup..."
mysqldump -h "$rds_endpoint" \
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
