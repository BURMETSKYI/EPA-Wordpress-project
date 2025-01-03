#!/bin/bash
set -euo pipefail

# Configuration
rds_endpoint=RDS_ENDPOINT  # Replace with RDS endpoint
db_username=DB_USERNAME   # Replace with RDS admin username
db_password=DB_PASSWORD   # Replace with RDS admin password
domain=S_DOMAIN
S3_MOUNT="/home/ubuntu/s3-epa"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Status tracking
declare -A STATUS

check_nginx() {
    echo "Checking Nginx..."
    if systemctl is-active --quiet nginx; then
        STATUS["Nginx"]="${GREEN}Running${NC}"
        curl -Is "https://$domain" > /dev/null 2>&1 && \
            STATUS["Website"]="${GREEN}Accessible${NC}" || \
            STATUS["Website"]="${RED}Not Accessible${NC}"
    else
        STATUS["Nginx"]="${RED}Not Running${NC}"
        STATUS["Website"]="${RED}Not Accessible${NC}"
    fi
}

check_php() {
    echo "Checking PHP-FPM..."
    if systemctl is-active --quiet php8.3-fpm; then
        STATUS["PHP-FPM"]="${GREEN}Running${NC}"
    else
        STATUS["PHP-FPM"]="${RED}Not Running${NC}"
    fi
}

check_database() {
    echo "Checking Database..."
    if mysql -h "$rds_endpoint" -u "$db_username" -p"$db_password" -e "SELECT 1;" > /dev/null 2>&1; then
        STATUS["Database"]="${GREEN}Connected${NC}"
        
        # Check WordPress tables
        if mysql -h "$rds_endpoint" -u "$db_username" -p"$db_password" -e "USE admin; SELECT COUNT(*) FROM wp_options;" > /dev/null 2>&1; then
            STATUS["WordPress Tables"]="${GREEN}OK${NC}"
        else
            STATUS["WordPress Tables"]="${RED}Missing${NC}"
        fi
    else
        STATUS["Database"]="${RED}Connection Failed${NC}"
        STATUS["WordPress Tables"]="${RED}Not Accessible${NC}"
    fi
}

check_ssl() {
    echo "Checking SSL..."
    ssl_expiry=$(echo | openssl s_client -servername "$domain" -connect "$domain":443 2>/dev/null | openssl x509 -noout -enddate | cut -d= -f2)
    if [ ! -z "$ssl_expiry" ]; then
        expiry_date=$(date -d "$ssl_expiry" +%s)
        current_date=$(date +%s)
        days_left=$(( ($expiry_date - $current_date) / 86400 ))
        
        if [ $days_left -gt 30 ]; then
            STATUS["SSL Certificate"]="${GREEN}Valid ($days_left days left)${NC}"
        elif [ $days_left -gt 0 ]; then
            STATUS["SSL Certificate"]="${YELLOW}Expiring Soon ($days_left days left)${NC}"
        else
            STATUS["SSL Certificate"]="${RED}Expired${NC}"
        fi
    else
        STATUS["SSL Certificate"]="${RED}Not Found${NC}"
    fi
}

check_s3() {
    echo "Checking S3 Mount..."
    if mountpoint -q "$S3_MOUNT"; then
        STATUS["S3 Mount"]="${GREEN}Mounted${NC}"
        if [ -d "$S3_MOUNT/wp-content" ]; then
            STATUS["S3 Content"]="${GREEN}Accessible${NC}"
        else
            STATUS["S3 Content"]="${RED}Missing wp-content${NC}"
        fi
    else
        STATUS["S3 Mount"]="${RED}Not Mounted${NC}"
        STATUS["S3 Content"]="${RED}Not Accessible${NC}"
    fi
}

check_disk_space() {
    echo "Checking Disk Space..."
    disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$disk_usage" -lt 80 ]; then
        STATUS["Disk Space"]="${GREEN}OK ($disk_usage%)${NC}"
    elif [ "$disk_usage" -lt 90 ]; then
        STATUS["Disk Space"]="${YELLOW}Warning ($disk_usage%)${NC}"
    else
        STATUS["Disk Space"]="${RED}Critical ($disk_usage%)${NC}"
    fi
}

check_memory() {
    echo "Checking Memory Usage..."
    memory_usage=$(free | awk '/Mem:/ {printf("%.0f"), $3/$2 * 100}')
    if [ "$memory_usage" -lt 80 ]; then
        STATUS["Memory Usage"]="${GREEN}OK ($memory_usage%)${NC}"
    elif [ "$memory_usage" -lt 90 ]; then
        STATUS["Memory Usage"]="${YELLOW}Warning ($memory_usage%)${NC}"
    else
        STATUS["Memory Usage"]="${RED}Critical ($memory_usage%)${NC}"
    fi
}

print_status() {
    echo ""
    echo "Status Report for $domain"
    echo "=================================="
    for key in "${!STATUS[@]}"; do
        printf "%-20s : %s\n" "$key" "${STATUS[$key]}"
    done
    echo "=================================="
    echo "Last checked: $(date)"
}

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
if echo "${STATUS[@]}" | grep -q "Not Running\|Failed\|Critical\|Not Accessible"; then
    exit 1
else
    exit 0
fi
