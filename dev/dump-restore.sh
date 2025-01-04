#!/bin/bash
set -euo pipefail

# Constants
rds_edpoint=RDS_ENDPOINT  # Replace with RDS endpoint
db_username=DB_USERNAME   # Replace with RDS admin username
db_password=DB_PASSWORD   # Replace with RDS admin password
backup_file="/home/ubuntu/s3-epa/wp_backup.sql"  # Note: changed from s3_epa to s3-epa

# Function to check exit status
check_exit_status() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed. Exiting."
        exit 1
    fi
}

# Check if backup file exists
echo "Checking for backup file..."
if [ ! -f "$backup_file" ]; then
    echo "Error: Backup file not found at $backup_file"
    echo "Available files in directory:"
    ls -l "$(dirname "$backup_file")"
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
if mysql -h "$rds_endpoint" \
   -u "$db_username" \
   -p"$db_password" \
   < "$backup_file"; then
    echo "Database import successful"
else
    echo "Error: Database import failed"
    exit 1
fi

# Verify import
echo "Verifying database import..."
mysql -h "$rds_endpoint" \
-u "$db_username" \
-p"$db_password" \
-e "USE admin; SELECT option_name, option_value FROM wp_options WHERE option_name IN ('siteurl', 'home');"

echo "Database restore completed successfully!"
