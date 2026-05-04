#!/bin/bash
# update_cpanel.sh
# Force update cPanel, check version, and restart cpsrvd with progress output

LOGFILE="/var/log/update_cpanel.log"

echo "===== Starting cPanel update at $(date) =====" | tee -a $LOGFILE

echo "[*] Running cPanel update..."
/scripts/upcp --force 2>&1 | tee -a $LOGFILE

echo "[*] Checking cPanel version..."
/usr/local/cpanel/cpanel -V 2>&1 | tee -a $LOGFILE

echo "[*] Restarting cpsrvd service..."
/scripts/restartsrv_cpsrvd --hard 2>&1 | tee -a $LOGFILE

echo "===== Completed cPanel update at $(date) =====" | tee -a $LOGFILE

