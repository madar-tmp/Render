#!/bin/bash
set -e

echo "🚀 Starting Render Free Server with WireGuard..."

# Setup WireGuard
echo "🔧 Configuring WireGuard..."
/wireguard-setup.sh

# Start ngrok tunnel for WireGuard (UDP)
echo "📡 Starting ngrok tunnel for WireGuard (UDP)..."
ngrok tcp 51820 --authtoken $NGROK_AUTH_TOKEN --log=stdout > /tmp/ngrok.log 2>&1 &

# Wait for ngrok to start
sleep 5

# Get ngrok public URL
NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url')
echo "✅ WireGuard available at: $NGROK_URL"

# Save ngrok URL to file
echo $NGROK_URL > /config/ngrok_url.txt

# Generate WireGuard client config
cat > /config/client.conf <<EOF
[Interface]
PrivateKey = $(cat /etc/wireguard/client_private.key)
Address = 10.0.0.2/24
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = $(cat /etc/wireguard/server_public.key)
Endpoint = $(echo $NGROK_URL | sed 's/tcp:\/\///')
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

echo "📝 Client config saved to /config/client.conf"

# Start keepalive in background to prevent Render from sleeping
/keepalive.sh &

# Start nginx with basic auth
echo "🌐 Starting nginx on port 8080..."
nginx -g "daemon off;"