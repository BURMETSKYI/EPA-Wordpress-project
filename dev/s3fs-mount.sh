#!/bin/bash
set -euo pipefail

# Function to check exit status
check_exit_status() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed. Exiting."
        exit 1
    fi
}

# Function to wait for mount
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
    sudo mkdir -p /tmp/s3fs_cache
    sudo chmod 777 /tmp/s3fs_cache
    
    echo deadline | sudo tee /sys/block/xvda/queue/scheduler
    sudo blockdev --setra 2048 /dev/xvda
    
    sudo sysctl -w vm.dirty_ratio=80
    sudo sysctl -w vm.dirty_background_ratio=5
    sudo sysctl -w vm.dirty_expire_centisecs=12000
}

# Constants
storage_url=STORAGE_URL
MOUNT_POINT="/home/ubuntu/s3-epa"

# Setup mount point
echo "Setting up persistent storage..."
mkdir -p $MOUNT_POINT
sudo chown ubuntu: $MOUNT_POINT
sudo chmod 755 $MOUNT_POINT

# Install s3fs
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

# Configure FUSE
echo "Configuring FUSE..."
sudo sed -i 's/^#user_allow_other/user_allow_other/' /etc/fuse.conf
check_exit_status "FUSE configuration"

echo "Applying system optimizations..."
setup_system_optimizations

# Mount S3 bucket
echo "Mounting S3 bucket..."
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

# Wait for mount
wait_for_mount "$MOUNT_POINT"
check_exit_status "S3 storage mount"

echo "S3 bucket mounted successfully!"
