#!/bin/bash

# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Start tailscaled in background
sudo tailscaled --state=/var/lib/tailscale/tailscaled.state \
  --socket=/var/run/tailscale/tailscaled.sock \
  --tun=userspace-networking \
  --socks5-server=localhost:1055 \
  --outbound-http-proxy-listen=localhost:1055 &

# Give it time to start
sleep 3

# CORRECT SYNTAX - with --auth-key= prefix
sudo tailscale up --ssh --auth-key=${TAILSCALE_AUTHKEY} --hostname=${TAILSCALE_HOSTNAME:-render-vpn} --advertise-exit-node

# Keep alive
tail -f /dev/null