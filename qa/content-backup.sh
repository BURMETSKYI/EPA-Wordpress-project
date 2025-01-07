#!/bin/bash
set -euo pipefail

# Constants
SOURCE="/var/www/html/wp-content/"
TARGET="/home/ubuntu/s3-epa/"
LOG_DIR="/home/ubuntu/s3-epa/logs"
LOG_FILE="$LOG_DIR/wp-content-backup.log"

# Ensure logs directory exists
mkdir -p "$LOG_DIR"

# Ensure directories exist
if [ ! -d "$SOURCE" ]; then
    echo "$(date +"%Y-%m-%d %H:%M:%S"): Source directory does not exist: $SOURCE" | tee -a "$LOG_FILE"
    exit 1
fi

if [ ! -d "$TARGET" ]; then
    echo "$(date +"%Y-%m-%d %H:%M:%S"): Target directory does not exist: $TARGET" | tee -a "$LOG_FILE"
    exit 1
fi

# Copy wp-content to S3 mount
echo "$(date +"%Y-%m-%d %H:%M:%S"): Copying wp-content to S3 mount point..." | tee -a "$LOG_FILE"
sudo cp -r "$SOURCE" "$TARGET"

echo "$(date +"%Y-%m-%d %H:%M:%S"): Copy completed successfully." | tee -a "$LOG_FILE"
