#!/bin/bash

# Enable strict error handling
set -euo pipefail

# Constants
rds_edpoint=RDS_ENDPOINT  # Replace with RDS endpoint
db_username=DB_USERNAME   # Replace with RDS admin username
db_password=DB_PASSWORD   # Replace with RDS admin password
WP_ROOT="/var/www/html"

# Functions for error handling
function check_exit_status {
    if [ $? -ne 0 ]; then
        echo "$1 failed. Exiting."
        exit 1
    fi
}

# Function to generate secure salts
generate_wp_salts() {
    curl -s https://api.wordpress.org/secret-key/1.1/salt/
}

# Function to validate database connection
validate_db_connection() {
    if ! mysql -h "$rds_endpoint" -u "$db_username" -p"$db_password" -e "SELECT 1;" &>/dev/null; then
        echo "Error: Cannot connect to database. Please check credentials and endpoint."
        exit 1
    fi
}

# Install required packages
echo "Installing required packages..."
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y unzip wget mariadb-client php-mysql
check_exit_status "Package installation"

# Validate database connection before proceeding
echo "Validating database connection..."
validate_db_connection

# Clean existing installation
echo "Cleaning up existing WordPress installation..."
sudo rm -rf "$WP_ROOT"
sudo mkdir -p "$WP_ROOT"

# Download and extract WordPress
echo "Downloading latest WordPress..."
TMP_DIR=$(mktemp -d)
wget -q -O "$TMP_DIR/latest.zip" https://wordpress.org/latest.zip
check_exit_status "WordPress download"

echo "Extracting WordPress files..."
unzip -q "$TMP_DIR/latest.zip" -d "$TMP_DIR"
sudo cp -r "$TMP_DIR/wordpress/." "$WP_ROOT/"
check_exit_status "WordPress extraction"

# Clean up temporary files
rm -rf "$TMP_DIR"

# Move WordPress to the correct location
echo "Setting up WordPress directory..."
sudo mv /var/www/wordpress /var/www/html
sudo rm /var/www/latest.zip
check_exit_status "WordPress setup"

# Create database
echo "Setting up database..."
mysql -h "$rds_endpoint" -u "$db_username" -p"$db_password" <<EOF
CREATE DATABASE IF NOT EXISTS ${db_username};
EOF
check_exit_status "Database creation"

# Configure WordPress
echo "Configuring WordPress..."
sudo cp "$WP_ROOT/wp-config-sample.php" "$WP_ROOT/wp-config.php"

# Update database configuration
sudo sed -i "s/database_name_here/$db_username/g" "$WP_ROOT/wp-config.php"
sudo sed -i "s/username_here/$db_username/g" "$WP_ROOT/wp-config.php"
sudo sed -i "s/password_here/$db_password/g" "$WP_ROOT/wp-config.php"
sudo sed -i "s/localhost/$rds_endpoint/g" "$WP_ROOT/wp-config.php"

# Add security enhancements and performance optimizations
sudo cat >> "$WP_ROOT/wp-config.php" <<EOF

/* Security Enhancements */
define('DISALLOW_FILE_EDIT', true);
define('WP_AUTO_UPDATE_CORE', 'minor');
define('FORCE_SSL_ADMIN', true);

/* Performance Optimizations */
define('WP_CACHE', true);
define('WP_MEMORY_LIMIT', '256M');
define('WP_MAX_MEMORY_LIMIT', '512M');

/* Custom Upload Path */
define('UPLOADS', 'wp-content/uploads');
EOF

# Generate and add security salts
echo "Generating security salts..."
generate_wp_salts | sudo tee -a "$WP_ROOT/wp-config.php" > /dev/null

# Set proper permissions
echo "Setting permissions..."
sudo chown -R www-data:www-data "$WP_ROOT"
sudo find "$WP_ROOT" -type d -exec chmod 755 {} \;
sudo find "$WP_ROOT" -type f -exec chmod 644 {} \;
sudo chmod 640 "$WP_ROOT/wp-config.php"

# Create uploads directory with proper permissions
sudo mkdir -p "$WP_ROOT/wp-content/uploads"
sudo chown -R www-data:www-data "$WP_ROOT/wp-content/uploads"
sudo chmod 755 "$WP_ROOT/wp-content/uploads"

echo "WordPress setup completed successfully!"
echo "Please complete the installation by visiting your site."


