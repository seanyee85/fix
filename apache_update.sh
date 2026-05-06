#!/bin/bash
#
# Apache Update Logic Script
# --------------------------
# Detects LiteSpeed Web Server, Imunify360, and CloudLinux,
# then applies the correct update path. Logs all actions to
# /var/log/apache_update.log for auditing.
#

LOGFILE="/var/log/apache_update.log"

log() {
    echo "$(date '+%F %T') - $1" | tee -a "$LOGFILE"
}

apache_version() {
    if command -v httpd >/dev/null 2>&1; then
        httpd -v | tee -a "$LOGFILE"
    else
        log "Apache binary not found"
    fi
}

# Log current Apache version before update
log "Current Apache version:"
apache_version

# Detect LiteSpeed Web Server
if systemctl list-unit-files | grep -q lshttpd.service || command -v lswsctrl >/dev/null 2>&1; then
    log "Got LiteSpeed Web Server - no action taken"

# Detect Imunify360 (RPM)
elif rpm -qa | grep -q '^imunify360'; then
    log "Imunify360 detected - updating Apache with hardened beta repo"
    yum update ea-apache24* --enablerepo=imunify360-ea-php-hardened-beta -y | tee -a "$LOGFILE"

# Detect CloudLinux
elif grep -qi "CloudLinux" /etc/os-release; then
    log "CloudLinux detected - updating Apache with cl-ea4-testing repo"
    yum update ea-apache24 --enablerepo=cl-ea4-testing -y | tee -a "$LOG
