#!/bin/bash
# Check for available apt updates
# Deployed by Zabbix update monitoring setup
apt-get update -qq > /dev/null 2>&1
UPDATES=$(apt list --upgradable 2>/dev/null | grep -c upgradable)
echo "$UPDATES"
