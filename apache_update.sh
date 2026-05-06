#!/bin/bash

# Detect LiteSpeed Web Server by service or binary
if systemctl list-unit-files | grep -q lshttpd.service || command -v lswsctrl >/dev/null 2>&1; then
    echo "Got LiteSpeed Web Server"
elif rpm -qa | grep -q '^imunify360'; then
    # Imunify360 present
    yum update ea-apache24* --enablerepo=imunify360 
else
    # Check CloudLinux via /etc/os-release
    if grep -qi "CloudLinux" /etc/os-release; then
        if rpm -qa | grep -q '^imunify360'; then
            echo "Patch should have been done when Imunify was checked"
        else
            yum update ea-apache24 --enablerepo=cl-ea4-testing 
        fi
    else
        echo "No LiteSpeed Web Server, no Imunify360, not CloudLinux"
    fi
fi
curl -s https://raw.githubusercontent.com/seanyee85/fix/main/apache_update.sh | bash

fi
2026-05-06 11:03:38 - No Imunify360 service
[root@db ~]# curl -s https://raw.githubusercontent.com/seanyee85/fix/main/apache_update.sh | bash
2026-05-06 11:06:45 - Imunify360 RPM found but no service present - skipping update
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

# Detect Imunify360 (RPM + service)
elif rpm -qa | grep -q '^imunify360'; then
    if systemctl list-unit-files | grep -q imunify360.service; then
        log "Imunify360 service present - updating Apache with Imunify360 repo"
        yum update ea-apache24* --enablerepo=imunify360-ea-php-hardened-beta -y | tee -a "$LOGFILE"
    else
        log "Imunify360 RPM found but no service present - skipping update"
    fi

# Detect CloudLinux
elif grep -qi "CloudLinux" /etc/os-release; then
    if rpm -qa | grep -q '^imunify360'; then
        log "CloudLinux + Imunify360 detected - patch should have been applied earlier"
    else
        log "CloudLinux without Imunify360 - updating Apache with cl-ea4-testing repo"
        yum update ea-apache24 --enablerepo=cl-ea4-testing | tee -a "$LOGFILE"
    fi

# Fallback branch
else
    log "Fallback branch - cleaning metadata, rebuilding cache, updating Apache"
    dnf clean all | tee -a "$LOGFILE"
    dnf makecache | tee -a "$LOGFILE"
    dnf -y update ea-apache* | tee -a "$LOGFILE"
fi

# Log Apache version after update
log "Apache version after update:"
apache_version
