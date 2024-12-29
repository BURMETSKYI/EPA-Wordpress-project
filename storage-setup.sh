# S3fuse mount of persistent content storage
# Setting up a directory for the S3 mount point
echo "Setting up persistent storage..."
mkdir -p /home/ubuntu/s3-epa
sudo chown ubuntu:ubuntu /home/ubuntu/s3-epa
sudo chmod 755 /home/ubuntu/s3-epa

# Installing the s3fs tool for mounting S3 buckets
sudo apt install s3fs -y

# Configure FUSE to allow mounting with user permissions
sudo sed -i 's/^#user_allow_other/user_allow_other/' /etc/fuse.conf

# Mount the S3 bucket to the local directory
s3fs s3-epa /home/ubuntu/s3-epa -o iam_role=auto -o endpoint=eu-west-2 -o url=$storage_url -o allow_other -o use_path_request_style -o nonempty
check_exit_status "S3 storage mount"

# Replace WordPress content directory with the one from the persistent storage
sudo rm -rf /var/www/html/wp-content/
sudo cp -r /home/ubuntu/s3-epa/wp-content/ /var/www/html

# Set appropriate permissions for the WordPress content directory
sudo chown -R www-data: /var/www/html/wp-content/
sudo chmod 755 /var/www/html/wp-content/
