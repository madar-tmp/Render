# Use the official linuxserver/wireguard image as base
FROM lscr.io/linuxserver/wireguard:latest

# Install ngrok and nginx on top of the existing image
RUN apt-get update && apt-get install -y \
    curl \
    nginx \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install ngrok
RUN curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | tee /etc/apt/trusted.gpg.d/ngrok.asc \
    && echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | tee /etc/apt/sources.list.d/ngrok.list \
    && apt-get update && apt-get install -y ngrok \
    && rm -rf /var/lib/apt/lists/*

# Create necessary directories
RUN mkdir -p /config /var/www/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Create a simple index page
RUN echo '<html><body><h1>🚀 WireGuard VPN Server</h1><p><a href="/config/">📁 View Configs</a></p><p><a href="/health">✅ Health Check</a></p></body></html>' > /var/www/html/index.html

# Expose ports
EXPOSE 51820/udp 8080

# Use custom entrypoint
CMD ["/entrypoint.sh"]