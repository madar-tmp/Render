#!/bin/bash

# This script keeps Render instance alive by calling itself
RENDER_URL="https://${RENDER_EXTERNAL_HOSTNAME}.onrender.com"

while true; do
    echo "🔄 Keepalive ping at $(date)"
    curl -s -o /dev/null -w "%{http_code}" $RENDER_URL || true
    sleep 300  # Ping every 5 minutes
done