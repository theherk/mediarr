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
echo "API URL: http://${QBITTORRENT_HOST}/api/v2/app/setPreferences"
echo "Payload: json={\"listen_port\":${PORT}}"

response=$(wget -O- --post-data "json={\"listen_port\":${PORT}}" \
	--header "Content-Type: application/json" \
	"http://${QBITTORRENT_HOST}/api/v2/app/setPreferences" 2>&1)

exit_code=$?
echo "Exit code: ${exit_code}"
echo "Response: ${response}"

if [ ${exit_code} -ne 0 ]; then
	echo "Failed to set port"
	exit 1
fi

echo "Successfully set port to ${PORT}"
