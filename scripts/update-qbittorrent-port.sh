#!/bin/sh
# Update qBittorrent listening port when VPN port forwarding changes
# Called by Gluetun with port passed as first argument

PORT="$1"
QBITTORRENT_HOST="127.0.0.1:8080"

if [ -z "${PORT}" ]; then
	echo "Error: No port provided"
	exit 1
fi

echo "Waiting for qBittorrent to be ready..."
until wget -q --spider "http://${QBITTORRENT_HOST}/api/v2/app/version" 2>/dev/null; do
	sleep 2
done

echo "Setting qBittorrent listening port to ${PORT}"

# qBittorrent API returns empty 200 OK on success
# We need to check HTTP status code, not wget exit code
http_code=$(wget --server-response --post-data "json={\"listen_port\":${PORT}}" \
	"http://${QBITTORRENT_HOST}/api/v2/app/setPreferences" 2>&1 |
	grep "HTTP/" | tail -1 | awk '{print $2}')

echo "HTTP status code: ${http_code}"

if [ "${http_code}" != "200" ]; then
	echo "Failed to set port - HTTP ${http_code}"
	exit 1
fi

echo "Successfully set port to ${PORT}"
