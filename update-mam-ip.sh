#!/bin/bash

# MAM Dynamic Seedbox IP Update Script
# Updates MAM IP address when VPN IP changes
# Requires MAM_SESSION_ID environment variable

MAM_SESSION_ID="${MAM_SESSION_ID}"
COOKIE_FILE="/tmp/mam.cookies"

# Check if session ID is configured
if [ -z "$MAM_SESSION_ID" ]; then
    echo "ERROR: MAM_SESSION_ID environment variable not set"
    exit 1
fi

# Get current external IP from VPN container
CURRENT_IP=$(docker exec gluetun wget -qO- https://ipinfo.io/ip 2>/dev/null)
if [ -z "$CURRENT_IP" ]; then
    echo "ERROR: Could not determine VPN IP from Gluetun container"
    exit 1
fi

# Update MAM with current IP
RESPONSE=$(docker exec gluetun wget -qO- \
    --save-cookies="$COOKIE_FILE" \
    --header="Cookie: mam_id=$MAM_SESSION_ID" \
    https://t.myanonamouse.net/json/dynamicSeedbox.php 2>/dev/null)

# Parse response
SUCCESS=$(echo "$RESPONSE" | grep -o '"Success":[^,]*' | cut -d':' -f2)
MESSAGE=$(echo "$RESPONSE" | grep -o '"msg":"[^"]*' | cut -d'"' -f4)

if [ "$SUCCESS" = "true" ]; then
    echo "MAM IP updated to $CURRENT_IP"
else
    echo "ERROR: $MESSAGE"
    exit 1
fi
