#!/bin/bash
set -e

echo "Starting..."

if [ $# -gt 0 ]; then
    exec "$@"
fi

echo "Configuring hosts file for ad blocking..."
wc -l /hosts
sudo tee -a /etc/hosts < /hosts > /dev/null

# Continue with Selkies base image init system
if [ -x /init ]; then
    exec /init
else
    echo "Error: /init not found in base image"
    exit 1
fi