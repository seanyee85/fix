#!/bin/bash

#!/bin/bash

PKG="sf-whm-block"

# Check if package is already installed
if rpm -q $PKG >/dev/null 2>&1; then
    echo "$PKG is already installed. Updating..."
    dnf makecache --repo=ServerFreak-Repo && dnf update -y $PKG
else
    echo "$PKG is not installed. Installing..."
    dnf makecache --repo=ServerFreak-Repo && dnf install -y $PKG
fi
 
# Target version and build
TARGET_VERSION="134.0"
TARGET_BUILD="25"

# Get current WHM/cPanel version string
CURRENT=$(/usr/local/cpanel/cpanel -V 2>/dev/null)

# Extract version and build
CURRENT_VERSION=$(echo "$CURRENT" | awk '{print $1}')
CURRENT_BUILD=$(echo "$CURRENT" | awk -F'[()]' '{print $2}' | awk '{print $2}')

echo "Current WHM/cPanel version: $CURRENT_VERSION (build $CURRENT_BUILD)"

# Compare with target
if [ "$CURRENT_VERSION" != "$TARGET_VERSION" ] || [ "$CURRENT_BUILD" != "$TARGET_BUILD" ]; then
    echo "Version is not $TARGET_VERSION (build $TARGET_BUILD). Running /scripts/upcp..."
    /scripts/upcp --force
else
    echo "WHM/cPanel is already at $TARGET_VERSION (build $TARGET_BUILD). No update needed."
fi

