#!/bin/bash

# MAM IP Update Wrapper Script
# Sources environment variables and runs the main update script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source environment variables from .env file
if [ -f "$SCRIPT_DIR/.env" ]; then
    set -a
    source "$SCRIPT_DIR/.env"
    set +a
fi

# Run the main update script
exec "$SCRIPT_DIR/update-mam-ip.sh"
