#!/bin/bash
set -e

echo "🚀 Starting WireGuard VPN Server..."

# Set up IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
echo 1 > /proc/sys/net/ipv6/conf/all/forwarding

# Configure WireGuard
cat > /etc/wireguard/wg0.conf <<EOF
[Interface]
PrivateKey = $(wg genkey)
Address = ${INTERNAL_SUBNET}.1/24
ListenPort = ${SERVERPORT}
SaveConfig = false

# NAT rules
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
EOF

# Start WireGuard
wg-quick up wg0

# Start ngrok tunnel
if [ -n "$NGROK_AUTHTOKEN" ]; then
    echo "📡 Starting ngrok tunnel..."
    ngrok udp ${SERVERPORT} --authtoken ${NGROK_AUTHTOKEN} --log=stdout > /tmp/ngrok.log 2>&1 &
    
    # Wait and get ngrok URL
    sleep 5
    NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url' 2>/dev/null || echo "")
    echo "✅ ngrok tunnel: ${NGROK_URL}"
    echo ${NGROK_URL} > /config/ngrok_url.txt
fi

# Generate client configs
for peer in ${PEERS//,/ }; do
    mkdir -p /config/peer_${peer}
    PEER_KEY=$(wg genkey)
    PEER_PUB=$(echo ${PEER_KEY} | wg pubkey)
    
    # Add peer to server
    wg set wg0 peer ${PEER_PUB} allowed-ips ${INTERNAL_SUBNET}.$(($$ % 250 + 2))/32
    
    # Create client config
    cat > /config/peer_${peer}/peer_${peer}.conf <<EOF
[Interface]
PrivateKey = ${PEER_KEY}
Address = ${INTERNAL_SUBNET}.$(($$ % 250 + 2))/24
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = $(wg show wg0 public-key)
Endpoint = ${NGROK_URL:-localhost:${SERVERPORT}}
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF
    
    # Generate QR code if possible
    if command -v qrencode &> /dev/null; then
        qrencode -t ansiutf8 < /config/peer_${peer}/peer_${peer}.conf > /config/peer_${peer}/qr.txt
    fi
done

echo "✅ Client configs generated in /config/"

# Start nginx for web UI
nginx -g "daemon off;" &

# Keep container running
while true; do
    sleep 3600 &
    wait $!
done