#!/bin/bash
set -euo pipefail

# Test configuration
rds_endpoint=RDS_ENDPOINT  # Replace with RDS endpoint
db_username=DB_USERNAME   # Replace with RDS admin username
db_password=DB_PASSWORD   # Replace with RDS admin password
TEST_BACKUP="/home/ubuntu/s3-epa/wp_backup.sql"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Helper function for test results
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ $2 passed${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ $2 failed${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

echo "Starting tests..."

# Test 1: Check if backup file exists
echo "Test 1: Backup file existence"
if [ -f "$TEST_BACKUP" ]; then
    print_result 0 "Backup file exists"
else
    print_result 1 "Backup file not found"
fi

# Test 2: Check database connection
echo "Test 2: Database connection"
if mysql -h "$rds_endpoint" -u "$db_username" -p"$db_password" -e "SELECT 1;" > /dev/null 2>&1; then
    print_result 0 "Database connection"
else
    print_result 1 "Database connection"
fi

# Test 3: Check if backup file is valid SQL
echo "Test 3: Backup file validity"
if head -n 1 "$TEST_BACKUP" | grep -q "MySQL dump"; then
    print_result 0 "Backup file format"
else
    print_result 1 "Backup file format"
fi

# Test 4: Check if admin database exists
echo "Test 4: Database existence"
if mysql -h "$rds_endpoint" -u "$db_username" -p"$db_password" -e "USE admin;" > /dev/null 2>&1; then
    print_result 0 "Database exists"
else
    print_result 1 "Database exists"
fi

# Test 5: Check if WordPress tables exist
echo "Test 5: WordPress tables"
WP_TABLES=$(mysql -h "$rds_endpoint" -u "$db_username" -p"$db_password" -e "USE admin; SHOW TABLES LIKE 'wp_%';" 2>/dev/null)
if [ ! -z "$WP_TABLES" ]; then
    print_result 0 "WordPress tables exist"
else
    print_result 1 "WordPress tables exist"
fi

# Test 6: Check wp-options table
echo "Test 6: wp_options table"
if mysql -h "$rds_endpoint" -u "$db_username" -p"$db_password" -e "USE admin; SELECT option_name FROM wp_options WHERE option_name IN ('siteurl', 'home') LIMIT 1;" > /dev/null 2>&1; then
    print_result 0 "wp_options table"
else
    print_result 1 "wp_options table"
fi

# Print summary
echo ""
echo "Test Summary:"
echo "-------------"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $TESTS_FAILED"
echo "Total tests: $((TESTS_PASSED + TESTS_FAILED))"

# Exit with status code
if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi
