#!/bin/bash
set -euo pipefail

# Function to check exit status
check_exit_status() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed. Exiting."
        exit 1
    fi
}

# Function to copy directory with retry
copy_directory() {
    local src_dir=$1
    local dest_dir=$2
    local max_retries=3
    local retry=1

    while [ $retry -le $max_retries ]; do
        echo "Copying $src_dir (attempt $retry/$max_retries)..."
        if sudo rsync -av --progress \
            --timeout=1800 \
            --inplace \
            --no-whole-file \
            --exclude="*.tmp" \
            "$src_dir/" "$dest_dir/"; then
            return 0
        fi
        echo "Retry $retry failed, waiting before next attempt..."
        sleep 30
        ((retry++))
    done
    return 1
}

# Constants
MOUNT_POINT="/home/ubuntu/s3-epa"
WORDPRESS_CONTENT="/var/www/html/wp-content/"

# Verify mount point is accessible
if ! [ -d "$MOUNT_POINT/wp-content" ]; then
    echo "Error: wp-content directory not found in S3 mount"
    exit 1
fi

# Prepare WordPress directory
echo "Removing existing wp-content"
sudo rm -rf $WORDPRESS_CONTENT
sudo mkdir -p $WORDPRESS_CONTENT
check_exit_status "WordPress directory preparation"

# Copy files in stages
echo "Starting staged copy process..."

# Copy main directories separately
for dir in "themes" "plugins" "uploads"; do
    if [ -d "$MOUNT_POINT/wp-content/$dir" ]; then
        sudo mkdir -p "$WORDPRESS_CONTENT/$dir"
        if ! copy_directory "$MOUNT_POINT/wp-content/$dir" "$WORDPRESS_CONTENT/$dir"; then
            echo "Error: Failed to copy $dir directory after multiple attempts"
            exit 1
        fi
    fi
done

# Copy remaining files
echo "Copying remaining files..."
if ! sudo rsync -av --progress \
    --timeout=1800 \
    --inplace \
    --no-whole-file \
    --exclude={"themes","plugins","uploads"} \
    "$MOUNT_POINT/wp-content/" "$WORDPRESS_CONTENT/"; then
    echo "Error: Failed to copy remaining files"
    exit 1
fi

# Set permissions
echo "Setting permissions for wp-content..."
sudo chown -R www-data: $WORDPRESS_CONTENT
sudo chmod 755 $WORDPRESS_CONTENT
check_exit_status "Setting permissions"

echo "WordPress content copy completed successfully!"
