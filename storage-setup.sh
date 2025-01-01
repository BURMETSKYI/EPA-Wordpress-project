#!/bin/bash

# Function to check the exit status of the last command
check_exit_status() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed. Exiting."
        exit 1
    fi
}

# Set the S3 storage URL
storage_url=STORAGE_URL   # Replace with persistent storage URL

# Define the mount point
MOUNT_POINT="/home/ubuntu/s3-epa"
WORDPRESS_CONTENT="/var/www/html/wp-content/"


# Setting up a directory for the S3 mount point
echo "Setting up persistent storage..."
mkdir -p $MOUNT_POINT
sudo chown ubuntu: $MOUNT_POINT
sudo chmod 755 $MOUNT_POINT

# Installing the s3fs tool for mounting S3 buckets
sudo apt install s3fs -y

# Configure FUSE to allow mounting with user permissions
echo "Configuring FUSE..."
sudo sed -i 's/^#user_allow_other/user_allow_other/' /etc/fuse.conf
check_exit_status "FUSE configuration"

# Mount the S3 bucket to the local directory
echo "Mounting S3 bucket to $MOUNT_POINT..."
s3fs s3-epa $MOUNT_POINT -o iam_role=auto -o endpoint=eu-west-2 -o url=$storage_url -o allow_other -o use_path_request_style -o nonempty -o big_write -o write_bufsize=256k -o time_out=300
check_exit_status "S3 storage mount"

# Replace WordPress content directory with the one from the persistent storage
echo "Removing existing wp-content"
sudo rm -rf $WORDPRESS_CONTENT
check_exit_status "Folder wp-content removed"

# Copy the wp-content from the S3 bucket to the WordPress content directory
echo "Copying wp-content from S3 to $WORDPRESS_CONTENT..."
sudo cp -r $MOUNT_POINT/wp-content/ $WORDPRESS_CONTENT
check_exit_status "Copying wp-content"

# Set appropriate permissions for the WordPress content directory
echo "Setting permissions for wp-content..."
sudo chown -R www-data: $WORDPRESS_CONTENT
sudo chmod 755 $WORDPRESS_CONTENT
check_exit_status "Setting permissions"

echo "Persistent storage setup and WordPress content configuration completed successfully!"
