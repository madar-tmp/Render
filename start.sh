#!/bin/bash

# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Start Tailscaled
sudo tailscaled --state=/var/lib/tailscale/tailscaled.state \
  --socket=/var/run/tailscale/tailscaled.sock \
  --tun=userspace-networking \
  --socks5-server=localhost:1055 \
  --outbound-http-proxy-listen=localhost:1055 &

# Wait a moment for tailscaled to start
sleep 2

# Start Tailscale - FIXED: all on one line with proper line continuation
sudo tailscale up --ssh \
  --auth-key=${TAILSCALE_AUTHKEY} \
  --hostname=${TAILSCALE_HOSTNAME:-render-vpn} \
  --advertise-exit-node \
  ${TAILSCALE_ADDITIONAL_ARGS}

# Keep the container running
exec sleep infinity