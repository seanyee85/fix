#!/bin/bash

# Target version
TARGET_VERSION="11.134.0.25"

# Get current WHM/cPanel version
CURRENT_VERSION=$(/usr/local/cpanel/cpanel -V 2>/dev/null)

echo "Current WHM/cPanel version: $CURRENT_VERSION"

# Compare with target
if [ "$CURRENT_VERSION" != "$TARGET_VERSION" ]; then
    echo "Version is not $TARGET_VERSION. Running /scripts/upcp..."
    /scripts/upcp 
else
    echo "WHM/cPanel is already at $TARGET_VERSION. No update needed."
fi
