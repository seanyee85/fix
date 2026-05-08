#!/bin/bash

REPO_FILE="/etc/yum.repos.d/sf.repo"

# Check if repo file exists
if [ ! -f "$REPO_FILE" ]; then
    echo "[ServerFreak-Repo]
name=ServerFreak Repository
baseurl=https://repo.sfdns.net
enabled=1
gpgcheck=0" > "$REPO_FILE"
    echo "Created $REPO_FILE"
else
    dnf config-manager --set-enabled ServerFreak-Repo
    echo "Enabled ServerFreak-Repo"
fi

dnf makecache --repo=ServerFreak-Repo && dnf install -y sf-whm-block 
