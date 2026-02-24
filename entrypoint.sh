#!/bin/bash
set -e

echo "🚀 Starting WireGuard VPN Server..."

# Start ngrok tunnel
NGROK_URL=""
if [ -n "$NGROK_AUTH_TOKEN" ]; then
    echo "📡 Starting ngrok tunnel..."
    
    # Start ngrok in background
    ngrok udp 51820 --authtoken ${NGROK_AUTH_TOKEN} --log=stdout > /tmp/ngrok.log 2>&1 &
    
    # Wait for ngrok to initialize
    echo "⏳ Waiting for ngrok to initialize..."
    sleep 10
    
    # Try to get ngrok URL multiple times
    for i in {1..5}; do
        NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url' 2>/dev/null || echo "")
        if [ -n "$NGROK_URL" ] && [ "$NGROK_URL" != "null" ]; then
            break
        fi
        echo "⏳ Retrying ngrok URL... ($i/5)"
        sleep 5
    done
    
    if [ -n "$NGROK_URL" ] && [ "$NGROK_URL" != "null" ]; then
        echo "✅ ngrok tunnel: ${NGROK_URL}"
        echo ${NGROK_URL} > /config/ngrok_url.txt
    else
        echo "⚠️ Failed to get ngrok URL. Check logs:"
        cat /tmp/ngrok.log
    fi
fi

# Start nginx for web UI
echo "🌐 Starting nginx web UI on port 8080..."
nginx -g "daemon off;" &

# Show WireGuard status
echo "📊 WireGuard Status:"
wg show

# Keep container running and monitor
while true; do
    # Update ngrok URL if it changed
    if [ -n "$NGROK_AUTH_TOKEN" ]; then
        NEW_URL=$(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url' 2>/dev/null || echo "")
        if [ -n "$NEW_URL" ] && [ "$NEW_URL" != "null" ] && [ "$NEW_URL" != "$NGROK_URL" ]; then
            NGROK_URL=$NEW_URL
            echo "🔄 ngrok URL updated: ${NGROK_URL}"
            echo ${NGROK_URL} > /config/ngrok_url.txt
        fi
    fi
    
    sleep 60
done