#!/bin/bash
#
# Apache Update Script (Imunify360/AV servers)
# --------------------------------------------
# Order of checks:
# 1. Apache version (skip if already 2.4.67)
# 2. LiteSpeed (skip if running)
# 3. CloudLinux (priority, cl-ea4-testing repo)
# 4. Imunify360 (service + license-aware)
# 5. ImunifyAV (only if no Imunify360)
# 6. Fallback (standard update)
#
# Logs all actions to /var/log/apache_update.log
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

# Retry wrapper for yum/dnf commands
retry_update() {
    local cmd="$1"
    local max_attempts=5
    local attempt=1
    local delay=60

    until bash -c "$cmd"; do
        log "Attempt $attempt failed – retrying in $delay seconds..."
        if (( attempt >= max_attempts )); then
            log "All $max_attempts attempts failed – aborting."
            return 1
        fi
        attempt=$((attempt+1))
        sleep $delay
    done
    return 0
}

# Step 1: Check Apache version
CURRENT_VER=$(httpd -v 2>/dev/null | grep 'Server version' | awk '{print $3}' | cut -d/ -f2)
if [[ "$CURRENT_VER" == "2.4.67" ]]; then
    log "Apache version is already 2.4.67 - no action taken"
    exit 0
else
    log "Apache version is $CURRENT_VER - proceeding with update checks"
fi

# Step 2: LiteSpeed check
if systemctl is-active --quiet lshttpd.service; then
    log "LiteSpeed Web Server service is running - no action taken"
    exit 0
elif command -v lswsctrl >/dev/null 2>&1 && lswsctrl status 2>/dev/null | grep -qi "running"; then
    log "LiteSpeed Web Server is running (via lswsctrl) - no action taken"
    exit 0
fi

# Step 3: CloudLinux check
if grep -qi "CloudLinux" /etc/os-release; then
    log "CloudLinux detected - updating Apache with cl-ea4-testing repo"
    retry_update "yum update ea-apache24 --enablerepo=cl-ea4-testing -y | tee -a $LOGFILE"

# Step 4: Imunify360 check
elif systemctl is-active --quiet imunify360.service; then
    LICENSE_TYPE=$(imunify360-agent config show --json -v | jq -r '.license.license_type' 2>/dev/null)
    LICENSE_STATUS=$(imunify360-agent rstatus 2>/dev/null | tr -d '\n')

    if [[ "$LICENSE_TYPE" == "imunify360" && "$LICENSE_STATUS" == "OK" ]]; then
        log "Imunify360 service running with valid license - updating Apache with hardened repo"
        retry_update "yum update ea-apache24* --enablerepo=imunify360-ea-php-hardened-beta -y | tee -a $LOGFILE"
    else
        log "Imunify360 detected but license not OK - running standard Apache update"
        retry_update "dnf -y update ea-apache* | tee -a $LOGFILE"
    fi

# Step 5: ImunifyAV check
elif command -v imunify-antivirus >/dev/null 2>&1; then
    LICENSE_STATUS=$(imunify-antivirus rstatus 2>/dev/null | tr -d '\n')
    if [[ "$LICENSE_STATUS" == "OK" ]]; then
        log "ImunifyAV detected - running standard Apache update"
    else
        log "ImunifyAV detected but rstatus not OK - still running standard Apache update"
    fi
    retry_update "dnf -y update ea-apache* | tee -a $LOGFILE"

# Step 6: Fallback
else
    log "No Imunify product detected - running standard Apache update"
    retry_update "dnf -y update ea-apache* | tee -a $LOGFILE"
fi

# Step 7: Log Apache version after update
log "Apache version after update:"
apache_version
