#!/bin/bash

# Enable error handling
set -euo pipefail

# Function to check the exit status of the last command
check_exit_status() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed. Exiting."
        exit 1
    fi
}

# Function to wait for mount to be ready
wait_for_mount() {
    local mount_point=$1
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if mountpoint -q "$mount_point"; then
            echo "Mount successful!"
            return 0
        fi
        echo "Waiting for mount to be ready (attempt $attempt/$max_attempts)..."
        sleep 10
        ((attempt++))
    done
    
    echo "Mount point not ready after $max_attempts attempts"
    return 1
}

# System optimizations
setup_system_optimizations() {
    # Create cache directories
    sudo mkdir -p /tmp/s3fs_cache
    sudo chmod 777 /tmp/s3fs_cache
    
    # Optimize I/O scheduler
    echo deadline | sudo tee /sys/block/xvda/queue/scheduler
    sudo blockdev --setra 2048 /dev/xvda
    
    # Optimize VM parameters
    sudo sysctl -w vm.dirty_ratio=80
    sudo sysctl -w vm.dirty_background_ratio=5
    sudo sysctl -w vm.dirty_expire_centisecs=12000
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

# Set the S3 storage URL
storage_url=STORAGE_URL   # Replace with persistent storage URL

# Define the mount point
MOUNT_POINT="/home/ubuntu/s3-epa"
WORDPRESS_CONTENT="/var/www/html/wp-content/"
CACHE_DIR="/tmp/s3fs_cache"


# Setting up a directory for the S3 mount point
echo "Setting up persistent storage..."
mkdir -p $MOUNT_POINT
sudo chown ubuntu: $MOUNT_POINT
sudo chmod 755 $MOUNT_POINT

# Installing the s3fs tool for mounting S3 buckets with retry
echo "Installing s3fs..."
for i in {1..3}; do
    if sudo apt-get update && sudo apt-get install s3fs -y; then
        break
    fi
    if [ $i -eq 3 ]; then
        echo "Failed to install s3fs after 3 attempts"
        exit 1
    fi
    echo "Retrying s3fs installation..."
    sleep 5
done

# Configure FUSE to allow mounting with user permissions
echo "Configuring FUSE..."
sudo sed -i 's/^#user_allow_other/user_allow_other/' /etc/fuse.conf
check_exit_status "FUSE configuration"

echo "Applying system optimizations..."
setup_system_optimizations


# Mount the S3 bucket to the local directory
s3fs s3-epa "$MOUNT_POINT" \
    -o iam_role=auto \
    -o endpoint=eu-west-2 \
    -o url="$storage_url" \
    -o allow_other \
    -o use_path_request_style \
    -o nonempty \
    -o kernel_cache \
    -o max_stat_cache_size=10000 \
    -o parallel_count=15 \
    -o use_cache="/tmp/s3fs_cache" \
    -o stat_cache_expire=30 \
    -o enable_noobj_cache \
    -o connect_timeout=60 \
    -o retries=5 \
    -o umask=0002


# Wait for mount to be ready
wait_for_mount "$MOUNT_POINT"
check_exit_status "S3 storage mount"

# Verify the mount point is accessible
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

# Set appropriate permissions for the WordPress content directory
echo "Setting permissions for wp-content..."
sudo chown -R www-data: $WORDPRESS_CONTENT
sudo chmod 755 $WORDPRESS_CONTENT
check_exit_status "Setting permissions"

echo "Persistent storage setup and WordPress content configuration completed successfully!"
