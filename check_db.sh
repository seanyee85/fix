#!/bin/bash
# check_db.sh - Detect DB engine/version and apply versionlock if MySQL 8.0

echo "Checking database version on $(hostname)..."

DB_INFO=$(mysql --version 2>/dev/null || mariadb --version 2>/dev/null)

if [[ -z "$DB_INFO" ]]; then
    echo "No MySQL/MariaDB client found"
elif [[ $DB_INFO == *"MariaDB"* ]]; then
    echo "MariaDB detected"
elif [[ $DB_INFO == *"Ver 8.0"* ]]; then
    echo "MySQL 8.0 detected"
    # Ensure versionlock plugin is installed
    dnf install -y 'dnf-command(versionlock)'
    dnf versionlock add mysql-community-*
elif [[ $DB_INFO == *"Ver 9.7"* ]]; then
    echo "ERROR - MySQL 9.7 detected"
else
    echo "Unknown DB version ($DB_INFO)"
fi
