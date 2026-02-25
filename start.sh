#!/bin/bash

# 1. Install Tailscale (Force non-interactive)
curl -fsSL https://tailscale.com/install.sh | sh

# 2. Start the Tailscale daemon in userspace mode
# We remove 'sudo' because Render/Cloud Shell containers usually run as the only user.
tailscaled --tun=userspace-networking --socks5-server=localhost:1080 &

# 3. Wait for the background process to initialize
sleep 5

# 4. Connect to Tailscale
# Removed 'sudo'. Fixed hostname syntax to ${VAR:-default}.
tailscale up \
  --auth-key="${TAILSCALE_AUTHKEY}" \
  --hostname="${TAILSCALE_HOSTNAME:-render-vpn}" \
  --ssh \
  --advertise-exit-node

# 5. Keep the process alive
# Using 'wait' is cleaner for Docker/Render than tail -f /dev/null
wait
