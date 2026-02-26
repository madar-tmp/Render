#!/bin/bash

# CRITICAL: Start a web server on $PORT for Render health checks
# Simple Python HTTP server (always running)
python3 -m http.server ${PORT:-10000} --directory /tmp &

# OR use netcat for even less overhead:
# while true; do echo -e "HTTP/1.1 200 OK\n\nRender Tailscale Running" | nc -l -p ${PORT:-10000} -q 1; done &

# Start Tailscale daemon
sudo tailscaled --tun=userspace-networking --verbose=1 &
#tailscaled --tun=userspace-networking --verbose=1 &
sleep 5

# Up with exit node
tailscale up \
  --auth-key="${TAILSCALE_AUTHKEY}" \
  --hostname="${TAILSCALE_HOSTNAME}" \
  --advertise-exit-node \
  --ssh \
  --accept-dns=true

# Keep container alive with periodic status updates
while true; do
  echo "$(date): Tailscale status - $(tailscale status --json | jq -r '.Self.Online')"
  
  # Touch a file to keep the web server serving fresh content
  echo "Last updated: $(date)" > /tmp/index.html
  
  sleep 60
done
