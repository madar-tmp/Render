#!/bin/bash

# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Start Tailscaled with logging
sudo tailscaled --state=/var/lib/tailscale/tailscaled.state \
  --socket=/var/run/tailscale/tailscaled.sock \
  --tun=userspace-networking \
  --socks5-server=localhost:1055 \
  --outbound-http-proxy-listen=localhost:1055 > /tmp/tailscaled.log 2>&1 &

# Wait longer for tailscaled to initialize
echo "Waiting for tailscaled to start..."
sleep 5

# Check if tailscaled is running
if ! pgrep -f tailscaled > /dev/null; then
    echo "ERROR: tailscaled failed to start"
    cat /tmp/tailscaled.log
    exit 1
fi

echo "tailscaled is running, attempting to authenticate..."

# Verify auth key is set
if [ -z "${TAILSCALE_AUTHKEY}" ]; then
    echo "ERROR: TAILSCALE_AUTHKEY environment variable is not set"
    exit 1
fi

# Run tailscale up with verbose output
sudo tailscale up \
  --ssh \
  --auth-key=${TAILSCALE_AUTHKEY} \
  --hostname=${TAILSCALE_HOSTNAME:-render-vpn} \
  --advertise-exit-node \
  ${TAILSCALE_ADDITIONAL_ARGS} 2>&1 | tee /tmp/tailscale-up.log

# Check if authentication succeeded
if [ $? -eq 0 ]; then
    echo "✅ Tailscale authenticated successfully!"
    sudo tailscale status
else
    echo "❌ Tailscale authentication failed"
    cat /tmp/tailscale-up.log
fi

# Keep the container running
exec sleep infinity