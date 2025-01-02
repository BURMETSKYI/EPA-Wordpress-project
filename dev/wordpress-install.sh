#!/bin/bash
set -euo pipefail

# Constants
rds_endpoint="database-1-green-uzyrnz.cfk4aya0a4fd.eu-west-2.rds.amazonaws.com"
db_username="admin"
db_password="Ujinsoap1322"
WP_ROOT="/var/www/html"
TMP_DIR="/tmp/wordpress_setup"

# Function for error handling
check_exit_status() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed. Exiting."
        exit 1
    fi
}

# Function to validate database connection
validate_db_connection() {
    if ! mysql -h "$rds_endpoint" -u "$db_username" -p"$db_password" -e "SELECT 1;" &>/dev/null; then
        echo "Error: Cannot connect to database. Please check credentials and endpoint."
        exit 1
    fi
}

echo "Starting WordPress installation..."

# Install required packages
echo "Installing required packages..."
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y unzip wget mariadb-client php-mysql
check_exit_status "Package installation"

# Validate database connection before proceeding
echo "Validating database connection..."
validate_db_connection

# Clean existing installation and create temporary directory
echo "Cleaning up existing WordPress installation..."
sudo rm -rf "$WP_ROOT"
sudo mkdir -p "$WP_ROOT"
mkdir -p "$TMP_DIR"

# Download and extract WordPress
echo "Downloading latest WordPress..."
wget -q -O "$TMP_DIR/latest.zip" https://wordpress.org/latest.zip
check_exit_status "WordPress download"

echo "Extracting WordPress files..."
unzip -q "$TMP_DIR/latest.zip" -d "$TMP_DIR"
check_exit_status "WordPress extraction"

# Move files to the correct location
echo "Setting up WordPress directory..."
sudo cp -r "$TMP_DIR/wordpress/"* "$WP_ROOT/"
check_exit_status "WordPress setup"

# Clean up temporary files
rm -rf "$TMP_DIR"

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
