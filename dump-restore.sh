#!/bin/bash
set -euo pipefail

# Constants
rds_endpoint=RDS_ENDPOINT
db_username=DB_USERNAME
db_password=DB_PASSWORD
backup_file="/home/ubuntu/s3_epa/wp_backup.sql"

# Check if backup file exists
echo "Checking for backup file..."
if [ ! -f "$backup_file" ]; then
   echo "Error: Backup file not found at $backup_file"
   exit 1
fi

# Verify database connection
echo "Verifying database connection..."
if ! mysql -h "$rds_endpoint" -u "$db_username" -p"$db_password" -e "SELECT 1;" > /dev/null 2>&1; then
   echo "Error: Cannot connect to target database"
   exit 1
fi

# Import database
echo "Importing database backup..."
mysql -h "$rds_endpoint" \
-u "$db_username" \
-p"$db_password" \
< "$backup_file"

# Verify import
echo "Verifying database import..."
mysql -h "$rds_endpoint" \
-u "$db_username" \
-p"$db_password" \
-e "USE admin; SELECT option_value FROM wp_options WHERE option_name IN ('siteurl', 'home');"

echo "Database restore completed successfully!"
