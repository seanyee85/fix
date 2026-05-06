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

# Detect LiteSpeed Web Server (service or binary)
if systemctl list-unit-files | grep -q lshttpd.service || command -v lswsctrl >/dev/null 2>&1; then
    log "Got LiteSpeed Web Server - no action taken"

# Detect Imunify360 (RPM + service)
elif rpm -qa | grep -q '^imunify360'; then
    if systemctl list-unit-files | grep -q imunify360.service; then
        log "Imunify360 service present - updating Apache with Imunify360 repo"
        yum update ea-apache24* --enablerepo=imunify360 -y | tee -a "$LOGFILE"
    else
        log "Imunify360 RPM found but no service present - skipping update"
    fi

# Detect CloudLinux
elif grep -qi "CloudLinux" /etc/os-release; then
    if rpm -qa | grep -q '^imunify360'; then
        log "CloudLinux + Imunify360 detected - patch should have been applied earlier"
    else
        log "CloudLinux without Imunify360 - updating Apache with cl-ea4-testing repo"
        yum update ea-apache24 --enablerepo=cl-ea4-testing -y | tee -a "$LOGFILE"
    fi

# Fallback branch
else
    log "Fallback branch - cleaning metadata, rebuilding cache, updating Apache"
    dnf clean all | tee -a "$LOGFILE"
    dnf makecache | tee -a "$LOGFILE"
    dnf -y update ea-apache* | tee -a "$LOGFILE"
fi
