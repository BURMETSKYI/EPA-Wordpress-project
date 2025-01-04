#!/bin/bash
# Constants
rds_endpoint=RDS_ENDPOINT  # Replace with RDS endpoint
db_username=DB_USERNAME   # Replace with RDS admin username
db_password=DB_PASSWORD_S   # Replace with RDS admin password

# Functions for error handling
function check_exit_status {
    if [ $? -ne 0 ]; then
        echo "$1 failed. Exiting."
        exit 1
    fi
}

# Generate secure keys from WordPress API
generate_secure_keys() {
    echo "Generating secure keys..."
    KEYS=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
    if [ -z "$KEYS" ]; then
        echo "Failed to generate secure keys"
        exit 1
    fi
}

# Install mariadb-client
echo "Installing required packages..."
sudo apt update
sudo apt -y install unzip wget mariadb-client
check_exit_status "Package installation"

# Validate database connection
echo "Validating database connection..."
if ! mysql -h "$rds_endpoint" -u "$db_username" -p"$db_password" "$db_username" -e "SELECT 1;" &>/dev/null; then
    echo "Error: Cannot connect to database. Please check credentials and endpoint."
    exit 1
fi

# Remove any existing WordPress installation
echo "Cleaning up existing WordPress installation..."
sudo rm -rf /var/www/html

# Download and extract WordPress
echo "Downloading the latest WordPress..."
sudo wget -O /var/www/latest.zip https://wordpress.org/latest.zip
check_exit_status "WordPress download"
echo "Extracting WordPress files..."
sudo unzip /var/www/latest.zip -d /var/www
check_exit_status "WordPress extraction"

# Move WordPress files
echo "Setting up WordPress directory..."
sudo mv /var/www/wordpress /var/www/html
sudo rm /var/www/latest.zip
check_exit_status "WordPress setup"

# Generate secure wp-config.php
echo "Configuring WordPress..."
generate_secure_keys

cat > /tmp/wp-config.php << EOL
<?php
/** Absolute path to the WordPress directory */
if ( !defined('ABSPATH') )
    define('ABSPATH', dirname(__FILE__) . '/');

/** Database Settings */
define('DB_NAME',     '$db_username');
define('DB_USER',     '$db_username');
define('DB_PASSWORD', '$db_password');
define('DB_HOST',     '$rds_endpoint');
define('DB_CHARSET',  'utf8');
define('DB_COLLATE',  '');

/** Security Keys */
$KEYS

/** Security Enhancements */
define('FORCE_SSL_ADMIN', true);
define('FORCE_SSL_LOGIN', true);
define('DISALLOW_FILE_EDIT', true);
define('DISALLOW_UNFILTERED_HTML', true);
define('ALLOW_UNFILTERED_UPLOADS', false);
define('DISABLE_WP_CRON', false);
define('AUTOMATIC_UPDATER_DISABLED', false);
define('WP_AUTO_UPDATE_CORE', 'minor');

/** Performance Settings */
define('WP_MEMORY_LIMIT', '256M');
define('WP_MAX_MEMORY_LIMIT', '512M');
define('WP_CACHE', true);

/** Custom Content Directory */
define('WP_CONTENT_DIR', ABSPATH . 'wp-content');
define('WP_CONTENT_URL', 'https://' . \$_SERVER['HTTP_HOST'] . '/wp-content');

/** Limit Login Attempts */
define('WP_LOGIN_ATTEMPTS', 5);

/** Debug Settings */
define('WP_DEBUG', false);
define('WP_DEBUG_LOG', false);
define('WP_DEBUG_DISPLAY', false);
@ini_set('display_errors', 0);

/** Database Table Prefix */
\$table_prefix = 'wp_';

/** Sets up WordPress vars and included files */
require_once ABSPATH . 'wp-settings.php';
EOL

# Move and secure wp-config.php
sudo mv /tmp/wp-config.php /var/www/html/wp-config.php
sudo chown www-data:www-data /var/www/html/wp-config.php
sudo chmod 600 /var/www/html/wp-config.php
sudo chown -R www-data:www-data /var/www/html
check_exit_status "WordPress configuration security"

echo "WordPress setup is complete with secure configuration."
