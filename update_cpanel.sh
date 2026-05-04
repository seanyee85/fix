
#!/bin/bash
# update_cpanel.sh
# Detect OS version, set WHM tier if required, then update cPanel

LOGFILE="/var/log/update_cpanel.log"

echo "===== Starting cPanel update at $(date) =====" | tee -a $LOGFILE

# Detect OS version
OS_VERSION=$(awk -F= '/^VERSION_ID/{print $2}' /etc/os-release 2>/dev/null | tr -d '"')
OS_NAME=$(awk -F= '/^ID/{print $2}' /etc/os-release 2>/dev/null | tr -d '"')

# Fallback for CentOS (older releases may not have /etc/os-release)
if [ -z "$OS_VERSION" ] && [ -f /etc/redhat-release ]; then
    if grep -q "CentOS release 6" /etc/redhat-release; then
        OS_NAME="centos"
        OS_VERSION="6"
    elif grep -q "CentOS Linux release 7" /etc/redhat-release; then
        OS_NAME="centos"
        OS_VERSION="7"
    fi
fi

echo "[*] Detected OS: $OS_NAME $OS_VERSION" | tee -a $LOGFILE

# Apply tier settings based on OS
if [ "$OS_NAME" = "centos" ] && [ "$OS_VERSION" = "6" ]; then
    echo "[*] Setting WHM tier to 11.110.0.103 for CentOS 6..." | tee -a $LOGFILE
    whmapi1 set_tier tier=11.110.0.103 >> $LOGFILE 2>&1
elif [ "$OS_NAME" = "centos" ] && [ "$OS_VERSION" = "7" ]; then
    echo "[*] Setting WHM tier to 11.110 for CentOS 7..." | tee -a $LOGFILE
    whmapi1 set_tier tier=11.110 >> $LOGFILE 2>&1
else
    echo "[*] AlmaLinux or other supported OS detected — skipping tier set." | tee -a $LOGFILE
fi

# Run update
echo "[*] Running cPanel update..."
/scripts/upcp --force 2>&1 | tee -a $LOGFILE

# Check version
echo "[*] Checking cPanel version..."
/usr/local/cpanel/cpanel -V 2>&1 | tee -a $LOGFILE

# Restart cpsrvd
echo "[*] Restarting cpsrvd service..."
/scripts/restartsrv_cpsrvd --hard 2>&1 | tee -a $LOGFILE

echo "===== Completed cPanel update at $(date) =====" | tee -a $LOGFILE
