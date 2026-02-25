#!/bin/bash

# 1. Start a tiny web server in the background to satisfy Render's health check
# Render gives you a port in the $PORT variable (usually 10000)
#python3 -m http.server ${PORT:-10000} &

# 2. Start Tailscale daemon
#tailscaled --tun=userspace-networking --socks5-server=localhost:1080 &
tailscaled --tun=userspace-networking &
sleep 5

# 3. Authenticate (Make sure you fixed the Auth Key as discussed!)
tailscale up \
  --auth-key="${TAILSCALE_AUTHKEY}" \
  --hostname="${TAILSCALE_HOSTNAME:-render-vpn}" \
  --advertise-exit-node \
  --ssh

wait
