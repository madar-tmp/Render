# Use multi-stage build
FROM lscr.io/linuxserver/wireguard:latest as wireguard-base

# Stage 2: Final image with all components
FROM ubuntu:22.04

# Install necessary packages
RUN apt-get update && apt-get install -y \
    curl \
    nginx \
    wireguard \
    wireguard-tools \
    iproute2 \
    iptables \
    resolvconf \
    && rm -rf /var/lib/apt/lists/*

# Install ngrok
RUN curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | tee /etc/apt/trusted.gpg.d/ngrok.asc \
    && echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | tee /etc/apt/sources.list.d/ngrok.list \
    && apt-get update && apt-get install -y ngrok \
    && rm -rf /var/lib/apt/lists/*

# Copy WireGuard binaries from the official image
COPY --from=wireguard-base /usr/bin/wg* /usr/bin/
COPY --from=wireguard-base /etc/wireguard/ /etc/wireguard/

# Create necessary directories
RUN mkdir -p /config /var/www/html /etc/nginx/sites-enabled

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Create a simple index page
RUN echo '<html><body><h1>WireGuard VPN Server</h1><p><a href="/config/">View Configs</a></p></body></html>' > /var/www/html/index.html

# Environment variables (with defaults)
ENV PUID=1000 \
    PGID=1000 \
    TZ=Asia/Kolkata \
    SERVERURL=auto \
    SERVERPORT=51820 \
    PEERS=phone,laptop \
    PEERDNS=auto \
    INTERNAL_SUBNET=10.13.13.0 \
    ALLOWEDIPS=0.0.0.0/0 \
    LOG_CONFS=true

# Expose ports
EXPOSE 51820/udp 8080

# Set capabilities
RUN setcap cap_net_admin+eip /usr/bin/wg

# Enable IP forwarding
RUN echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

# Start everything
CMD ["/entrypoint.sh"]