#!/bin/bash
# repo might still be on older cache
dnf makecache
# should be 1.3-1
dnf install sf-whm-block -y
