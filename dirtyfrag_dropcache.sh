#!/bin/bash
# Script: dirtyfrag_dropcache.sh

# Step 1: Block esp4, esp6, rxrpc modules
sudo sh -c "printf 'install esp4 /bin/false\ninstall esp6 /bin/false\ninstall rxrpc /bin/false\n' > /etc/modprobe.d/dirtyfrag.conf; rmmod esp4 esp6 rxrpc 2>/dev/null; true"

# Step 2: Drop caches
sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
