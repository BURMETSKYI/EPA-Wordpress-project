#!/bin/bash
set -euo pipefail

# Configuration - System Settings
rds_endpoint=RDS_ENDPOINT  # Replace with RDS endpoint
db_username=DB_USERNAME   # Replace with RDS admin username
db_password=DB_PASSWORD   # Replace with RDS admin password
domain=S_DOMAIN
S3_MOUNT="/home/ubuntu/s3-epa"

# Status icons
SUCCESS_ICON="✓"
ERROR_ICON="✗" 
WARNING_ICON="⚠"

# Status labels
OK_LABEL="${SUCCESS_ICON} [OK]"
WARN_LABEL="${WARNING_ICON} [WARNING]"
FAIL_LABEL="${ERROR_ICON} [FAILED]"

# Thresholds
DISK_WARN_THRESHOLD=80
DISK_CRIT_THRESHOLD=90
MEM_WARN_THRESHOLD=80
MEM_CRIT_THRESHOLD=90
SSL_WARN_DAYS=30
SSL_CRIT_DAYS=7

# Status tracking
declare -A STATUS
declare -A METRICS

print_status() {
   echo
   echo "Status Report for $domain"
   echo "=================================="
   # Print Critical Status First
   for key in "${!STATUS[@]}"; do
       if [[ ${STATUS[$key]} == *"$ERROR_ICON"* ]]; then
           printf "%-20s : %s\n" "$key" "${STATUS[$key]}"
       fi
   done
   # Print Warnings Second
   for key in "${!STATUS[@]}"; do
       if [[ ${STATUS[$key]} == *"$WARNING_ICON"* ]]; then
           printf "%-20s : %s\n" "$key" "${STATUS[$key]}"
       fi
   done
   # Print OK Status Last
   for key in "${!STATUS[@]}"; do
       if [[ ${STATUS[$key]} == *"$SUCCESS_ICON"* ]]; then
           printf "%-20s : %s\n" "$key" "${STATUS[$key]}"
       fi
   done
   echo "=================================="
   echo "Metrics Summary:"
   for key in "${!METRICS[@]}"; do
       printf "%-20s : %s\n" "$key" "${METRICS[$key]}"
   done
   echo "=================================="
   echo "Last checked: $(date)"
}

check_nginx() {
   echo "Checking Nginx..."
   if systemctl is-active --quiet nginx; then
       STATUS["Nginx"]="Running $OK_LABEL"
       curl -Is "https://$domain" > /dev/null 2>&1 && \
           STATUS["Website"]="Accessible $OK_LABEL" || \
           STATUS["Website"]="Not Accessible $FAIL_LABEL"
   else
       STATUS["Nginx"]="Not Running $FAIL_LABEL"
       STATUS["Website"]="Not Accessible $FAIL_LABEL"
   fi
}

check_php() {
   echo "Checking PHP-FPM..."
   if systemctl is-active --quiet php8.3-fpm; then
       STATUS["PHP-FPM"]="Running $OK_LABEL"
       METRICS["PHP Version"]="$(php -v | head -n1 | cut -d' ' -f2)"
   else
       STATUS["PHP-FPM"]="Not Running $FAIL_LABEL"
   fi
}

check_database() {
   echo "Checking Database..."
   if mysql -h "$rds_endpoint" -u "$db_username" -p"$db_password" -e "SELECT 1;" > /dev/null 2>&1; then
       STATUS["Database"]="Connected $OK_LABEL"
       if mysql -h "$rds_endpoint" -u "$db_username" -p"$db_password" -e "USE admin; SELECT COUNT(*) FROM wp_options;" > /dev/null 2>&1; then
           STATUS["WordPress Tables"]="OK $OK_LABEL"
           # Get WordPress version
           WP_VERSION=$(mysql -h "$rds_endpoint" -u "$db_username" -p"$db_password" -N -e "USE admin; SELECT option_value FROM wp_options WHERE option_name='db_version';")
           METRICS["WordPress Version"]="$WP_VERSION"
       else
           STATUS["WordPress Tables"]="Missing $FAIL_LABEL"
       fi
   else
       STATUS["Database"]="Connection Failed $FAIL_LABEL"
       STATUS["WordPress Tables"]="Not Accessible $FAIL_LABEL"
   fi
}

check_ssl() {
   echo "Checking SSL..."
   if ssl_expiry=$(echo | openssl s_client -servername "$domain" -connect "$domain":443 2>/dev/null | openssl x509 -noout -enddate | cut -d= -f2); then
       expiry_date=$(date -d "$ssl_expiry" +%s)
       current_date=$(date +%s)
       days_left=$(( ($expiry_date - $current_date) / 86400 ))
       METRICS["SSL Days Remaining"]="$days_left days"
       
       if [ $days_left -gt $SSL_WARN_DAYS ]; then
           STATUS["SSL Certificate"]="Valid $OK_LABEL"
       elif [ $days_left -gt $SSL_CRIT_DAYS ]; then
           STATUS["SSL Certificate"]="Expiring Soon $WARN_LABEL"
       else
           STATUS["SSL Certificate"]="Critical $FAIL_LABEL"
       fi
   else
       STATUS["SSL Certificate"]="Not Found $FAIL_LABEL"
   fi
}

check_s3() {
   echo "Checking S3 Mount..."
   if mountpoint -q "$S3_MOUNT"; then
       STATUS["S3 Mount"]="Mounted $OK_LABEL"
       if [ -d "$S3_MOUNT/wp-content" ]; then
           STATUS["S3 Content"]="Accessible $OK_LABEL"
           METRICS["S3 Size"]="$(du -sh $S3_MOUNT | cut -f1)"
       else
           STATUS["S3 Content"]="Missing wp-content $FAIL_LABEL"
       fi
   else
       STATUS["S3 Mount"]="Not Mounted $FAIL_LABEL"
       STATUS["S3 Content"]="Not Accessible $FAIL_LABEL"
   fi
}

check_disk_space() {
   echo "Checking Disk Space..."
   disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
   METRICS["Disk Usage"]="$disk_usage%"
   
   if [ "$disk_usage" -lt $DISK_WARN_THRESHOLD ]; then
       STATUS["Disk Space"]="OK $OK_LABEL"
   elif [ "$disk_usage" -lt $DISK_CRIT_THRESHOLD ]; then
       STATUS["Disk Space"]="Warning $WARN_LABEL"
   else
       STATUS["Disk Space"]="Critical $FAIL_LABEL"
   fi
}

check_memory() {
   echo "Checking Memory Usage..."
   memory_usage=$(free | awk '/Mem:/ {printf("%.0f"), $3/$2 * 100}')
   METRICS["Memory Usage"]="$memory_usage%"
   
   if [ "$memory_usage" -lt $MEM_WARN_THRESHOLD ]; then
       STATUS["Memory Usage"]="OK $OK_LABEL"
   elif [ "$memory_usage" -lt $MEM_CRIT_THRESHOLD ]; then
       STATUS["Memory Usage"]="Warning $WARN_LABEL"
   else
       STATUS["Memory Usage"]="Critical $FAIL_LABEL"
   fi
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

# Count issues
ERRORS=$(echo "${STATUS[@]}" | grep -o "$ERROR_ICON" | wc -l)
WARNINGS=$(echo "${STATUS[@]}" | grep -o "$WARNING_ICON" | wc -l)

# Exit with appropriate code
if [ $ERRORS -gt 0 ]; then
   echo "Found $ERRORS critical issues and $WARNINGS warnings!"
   exit 1
elif [ $WARNINGS -gt 0 ]; then
   echo "Found $WARNINGS warnings!"
   exit 0
else
   echo "All systems operational!"
   exit 0
fi
