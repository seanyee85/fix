#!/bin/bash
#
# Apache Update Logic Script
# --------------------------
# Checks Apache version first. If already 2.4.67, no action.
# Then LiteSpeed (must be running), then CloudLinux (priority),
# then Imunify360 (valid license), then ImunifyAV,
# and finally falls back to dnf update.
# Logs all actions to /var/log/apache_update.log.
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

# Step 1: Check Apache version first
CURRENT_VER=$(httpd -v 2>/dev/null | grep 'Server version' | awk '{print $3}' | cut -d/ -f2)
if [[ "$CURRENT_VER" == "2.4.67" ]]; then
    log "Apache version is already 2.4.67 - no action taken"
    exit 0
else
    log "Apache version is $CURRENT_VER - proceeding with update checks"
fi

# Step 2: LiteSpeed check (must be running)
if systemctl is-active --quiet lshttpd.service; then
    log "LiteSpeed Web Server service is running - no action taken"
    exit 0
elif command -v lswsctrl >/dev/null 2>&1 && lswsctrl status 2>/dev/null | grep -qi "running"; then
    log "LiteSpeed Web Server is running (via lswsctrl) - no action taken"
    exit 0

# Step 3: CloudLinux check (priority)
elif grep -qi "CloudLinux" /etc/os-release; then
    log "CloudLinux detected - updating Apache with cl-ea4-testing repo"
    yum update ea-apache24 --enablerepo=cl-ea4-testing -y | tee -a "$LOGFILE"

    if rpm -qa | grep -q '^imunify360'; then
        log "CloudLinux + Imunify360 detected - patch already done since CloudLinux handled it"
    fi

# Step 4: Imunify360 / ImunifyAV check (only if no CloudLinux)
else
    LICENSE_TYPE=$(imunify360-agent config show --json -v 2>/dev/null | jq -r '.license.license_type')
    LICENSE_STATUS=$(imunify360-agent rstatus 2>/dev/null | grep -i "status" | awk '{print $2}')

    if [[ "$LICENSE_TYPE" == "Imunify360" && "$LICENSE_STATUS" == "active" ]]; then
        log "Valid Imunify360 license detected - updating Apache with hardened beta repo"
        yum update ea-apache24* --enablerepo=imunify360-ea-php-hardened-beta -y | tee -a "$LOGFILE"

    elif [[ "$LICENSE_TYPE" == "ImunifyAV" ]]; then
        log "ImunifyAV license detected - running standard Apache update"
        dnf clean all | tee -a "$LOGFILE"
        dnf makecache | tee -a "$LOGFILE"
        dnf -y update ea-apache* | tee -a "$LOGFILE"

    else
        log "No valid Imunify license detected - falling back to standard Apache update"
        dnf clean all | tee -a "$LOGFILE"
        dnf makecache | tee -a "$LOGFILE"
        dnf -y update ea-apache* | tee -a "$LOGFILE"
    fi
fi

# Log Apache version after update
log "Apache version after update:"
apache_version
