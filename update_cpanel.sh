#!/bin/bash
# update_cpanel.sh
# Force update cPanel, check version, and restart cpsrvd

LOGFILE="/var/log/update_cpanel.log"

echo "===== Starting cPanel update at $(date) =====" >> $LOGFILE

/scripts/upcp --force >> $LOGFILE 2>&1
/usr/local/cpanel/cpanel -V >> $LOGFILE 2>&1
/scripts/restartsrv_cpsrvd --hard >> $LOGFILE 2>&1

echo "===== Completed cPanel update at $(date) =====" >> $LOGFILE
