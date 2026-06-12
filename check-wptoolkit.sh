#!/bin/bash

TARGET_VERSION="6.11.0"
echo "[INFO] Checking WP Toolkit version..."

CURRENT_VERSION=$(rpm -qa | grep wp-toolkit | awk -F'-' '{print $3}')

if [ -z "$CURRENT_VERSION" ]; then
    echo "[WARN] WP Toolkit not found. No action taken."
    exit 0
fi

echo "[INFO] Current WP Toolkit version: $CURRENT_VERSION"

if [ "$(printf '%s\n' "$TARGET_VERSION" "$CURRENT_VERSION" | sort -V | head -n1)" != "$TARGET_VERSION" ]; then
    echo "[ACTION] Updating WP Toolkit to $TARGET_VERSION..."
    bash <(curl -fsSL https://wp-toolkit.plesk.com/cPanel/installer.sh || wget -O - https://wp-toolkit.plesk.com/cPanel/installer.sh) --version "$TARGET_VERSION"
    echo "[DONE] Update process triggered."
else
    echo "[OK] WP Toolkit is already at $CURRENT_VERSION (>= $TARGET_VERSION)."
fi
