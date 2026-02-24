#!/bin/bash
set -e

echo "Starting Tailscale VPN..."

# Enable IP forwarding
echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
echo 'net.ipv6.conf.all.forwarding = 1' >> /etc/sysctl.conf
sysctl -p /etc/sysctl.conf

# Check for auth key
if [ -z "$TAILSCALE_AUTHKEY" ]; then
    echo "ERROR: TAILSCALE_AUTHKEY environment variable not set"
    exit 1
fi

# Start tailscaled
tailscaled --tun=userspace-networking --socks5-server=localhost:1055 \
  --outbound-http-proxy-listen=localhost:1055 &
  
# Wait for tailscaled to start
sleep 5

# Connect to Tailscale
tailscale up --authkey=${TAILSCALE_AUTHKEY} \
  --hostname=${TAILSCALE_HOSTNAME:-render-app} \
  --advertise-exit-node \
  --ssh \
  ${TAILSCALE_ADDITIONAL_ARGS}

echo "✅ Tailscale connected successfully"
echo "Tailscale IP: $(tailscale ip -4)"

# Keep container running
tail -f /dev/null