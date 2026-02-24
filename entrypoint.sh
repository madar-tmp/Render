#!/bin/bash
set -e

echo "🚀 Starting WireGuard VPN Server..."

# Set up IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
echo 1 > /proc/sys/net/ipv6/conf/all/forwarding

# Create WireGuard directory if it doesn't exist
mkdir -p /etc/wireguard

# Generate server private key if it doesn't exist
if [ ! -f /etc/wireguard/privatekey ]; then
    echo "🔑 Generating WireGuard server keys..."
    wg genkey | tee /etc/wireguard/privatekey | wg pubkey > /etc/wireguard/publickey
fi

SERVER_PRIVKEY=$(cat /etc/wireguard/privatekey)
SERVER_PUBKEY=$(cat /etc/wireguard/publickey)

# Create WireGuard server config
cat > /etc/wireguard/wg0.conf <<EOF
[Interface]
PrivateKey = ${SERVER_PRIVKEY}
Address = ${INTERNAL_SUBNET}.1/24
ListenPort = ${SERVERPORT}
SaveConfig = false

# NAT rules
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
EOF

# Start WireGuard
wg-quick up wg0 || true

# Start ngrok tunnel
NGROK_URL=""
if [ -n "$NGROK_AUTH_TOKEN" ]; then
    echo "📡 Starting ngrok tunnel..."
    # Kill any existing ngrok processes
    pkill ngrok || true
    
    # Start ngrok in background
    ngrok udp ${SERVERPORT} --authtoken ${NGROK_AUTH_TOKEN} --log=stdout > /tmp/ngrok.log 2>&1 &
    
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
        echo "⚠️ Failed to get ngrok URL. Check logs."
    fi
fi

# Generate client configs
echo "📱 Generating client configs for: ${PEERS}"

# Split PEERS by comma
IFS=',' read -ra PEER_ARRAY <<< "${PEERS}"

# Counter for IP assignment
IP_COUNTER=2

for peer in "${PEER_ARRAY[@]}"; do
    peer=$(echo $peer | xargs) # Trim whitespace
    echo "🔧 Creating config for: ${peer}"
    
    # Create peer directory
    mkdir -p /config/peer_${peer}
    
    # Generate peer keys
    PEER_PRIVKEY=$(wg genkey)
    PEER_PUBKEY=$(echo ${PEER_PRIVKEY} | wg pubkey)
    
    # Add peer to WireGuard
    wg set wg0 peer ${PEER_PUBKEY} allowed-ips ${INTERNAL_SUBNET}.${IP_COUNTER}/32
    
    # Use ngrok URL or fallback
    ENDPOINT="localhost:${SERVERPORT}"
    if [ -n "$NGROK_URL" ] && [ "$NGROK_URL" != "null" ]; then
        ENDPOINT=$(echo ${NGROK_URL} | sed 's/udp:\/\///')
    fi
    
    # Create client config
    cat > /config/peer_${peer}/peer_${peer}.conf <<EOF
[Interface]
PrivateKey = ${PEER_PRIVKEY}
Address = ${INTERNAL_SUBNET}.${IP_COUNTER}/24
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = ${SERVER_PUBKEY}
Endpoint = ${ENDPOINT}
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF
    
    # Also save as just the peer name for easier access
    cp /config/peer_${peer}/peer_${peer}.conf /config/peer_${peer}.conf
    
    # Try to generate QR code if qrencode is available
    if command -v qrencode &> /dev/null; then
        qrencode -t ansiutf8 < /config/peer_${peer}/peer_${peer}.conf > /config/peer_${peer}/qr.txt || true
        echo "✅ QR code generated for ${peer}"
    fi
    
    echo "✅ Config created for ${peer}"
    IP_COUNTER=$((IP_COUNTER + 1))
done

echo "✅ All client configs generated in /config/"

# Start nginx for web UI
echo "🌐 Starting nginx web UI on port 8080..."
nginx -g "daemon off;" &

# Show status
echo "📊 WireGuard Status:"
wg show

# Keep container running
while true; do
    sleep 3600 &
    wait $!
done