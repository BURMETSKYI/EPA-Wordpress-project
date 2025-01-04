#!/bin/bash
set -euo pipefail

# Configuration
rds_endpoint=RDS_ENDPOINT  # Replace with RDS endpoint
db_username=DB_USERNAME   # Replace with RDS admin username
db_password=DB_PASSWORD   # Replace with RDS admin password
domain=S_DOMAIN
S3_MOUNT="/home/ubuntu/s3-epa"

# ANSI Color codes for GitHub Actions compatible output
GREEN="✓"
RED="✗"
YELLOW="⚠"
OK=" [OK]"
WARN=" [WARNING]"
FAIL=" [FAILED]"

# Status tracking
declare -A STATUS

print_status() {
    echo ""
    echo "Status Report for $DOMAIN"
    echo "=================================="
    for key in "${!STATUS[@]}"; do
        printf "%-20s : %s\n" "$key" "${STATUS[$key]}"
    done
    echo "=================================="
    echo "Last checked: $(date)"
}

check_nginx() {
    echo "Checking Nginx..."
    if systemctl is-active --quiet nginx; then
        STATUS["Nginx"]="$GREEN Running$OK"
        curl -Is "https://$DOMAIN" > /dev/null 2>&1 && \
            STATUS["Website"]="$GREEN Accessible$OK" || \
            STATUS["Website"]="$RED Not Accessible$FAIL"
    else
        STATUS["Nginx"]="$RED Not Running$FAIL"
        STATUS["Website"]="$RED Not Accessible$FAIL"
    fi
}

check_php() {
    echo "Checking PHP-FPM..."
    if systemctl is-active --quiet php8.3-fpm; then
        STATUS["PHP-FPM"]="$GREEN Running$OK"
    else
        STATUS["PHP-FPM"]="$RED Not Running$FAIL"
    fi
}

check_database() {
    echo "Checking Database..."
    if mysql -h "$RDS_ENDPOINT" -u "$DB_USER" -p"$DB_PASS" -e "SELECT 1;" > /dev/null 2>&1; then
        STATUS["Database"]="$GREEN Connected$OK"
        if mysql -h "$RDS_ENDPOINT" -u "$DB_USER" -p"$DB_PASS" -e "USE admin; SELECT COUNT(*) FROM wp_options;" > /dev/null 2>&1; then
            STATUS["WordPress Tables"]="$GREEN OK$OK"
        else
            STATUS["WordPress Tables"]="$RED Missing$FAIL"
        fi
    else
        STATUS["Database"]="$RED Connection Failed$FAIL"
        STATUS["WordPress Tables"]="$RED Not Accessible$FAIL"
    fi
}

# Rest of your checks with similar formatting...

# Run all checks
check_nginx
check_php
check_database
check_ssl
check_s3
check_disk_space
check_memory

# Print results
print_status

# Exit with error if any service is down
if echo "${STATUS[@]}" | grep -q "\[FAILED\]"; then
    exit 1
fi

