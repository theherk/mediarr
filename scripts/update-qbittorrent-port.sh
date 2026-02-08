#!/bin/sh
# Update qBittorrent listening port when VPN port forwarding changes
# Called by Gluetun with $PORTS environment variable

QBITTORRENT_HOST="127.0.0.1:8080"

echo "Waiting for qBittorrent to be ready..."
until wget -q --spider "http://${QBITTORRENT_HOST}/api/v2/app/version" 2>/dev/null; do
	sleep 2
done

echo "Setting qBittorrent listening port to ${PORTS}"
wget --no-verbose -O /dev/null \
	--post-data "json={\"listen_port\":${PORTS}}" \
	--header "Content-Type: application/json" \
	"http://${QBITTORRENT_HOST}/api/v2/app/setPreferences" || {
	echo "Failed to set port"
	exit 1
}

echo "Successfully set port to ${PORTS}"
