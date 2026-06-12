#!/bin/bash

TARGET_VERSION="6.11.0"
CURRENT_VERSION=$(rpm -qa | grep wp-toolkit | awk -F'-' '{print $3}')

echo "Current WP Toolkit version: $CURRENT_VERSION"

if [ "$(printf '%s\n' "$TARGET_VERSION" "$CURRENT_VERSION" | sort -V | head -n1)" != "$TARGET_VERSION" ]; then
    echo "WP Toolkit version is lower than $TARGET_VERSION. Updating..."
    /usr/local/cpanel/3rdparty/wp-toolkit/bin/wp-toolkit-installer.sh --version "$TARGET_VERSION"
else
    echo "WP Toolkit is already at $CURRENT_VERSION (>= $TARGET_VERSION). No update needed."
fi
