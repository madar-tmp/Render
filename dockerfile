# Use Ubuntu base (easier for WireGuard)
FROM ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install basic tools
RUN apt-get update && apt-get install -y \
    nginx \
    curl \
    wget \
    unzip \
    iproute2 \
    iptables \
    wireguard \
    wireguard-tools \
    resolvconf \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

# Install ngrok
RUN curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | tee /etc/apt/trusted.gpg.d/ngrok.asc \
    && echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | tee /etc/apt/sources.list.d/ngrok.list \
    && apt-get update && apt-get install -y ngrok

# Setup nginx with basic auth
RUN mkdir -p /etc/nginx/secure && \
    echo "admin:$(openssl passwd -apr1 render)" > /etc/nginx/secure/.htpasswd

# Create WireGuard directory
RUN mkdir -p /etc/wireguard /config

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Copy nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# Copy WireGuard setup script
COPY wireguard-setup.sh /wireguard-setup.sh
RUN chmod +x /wireguard-setup.sh

# Copy keepalive script
COPY keepalive.sh /keepalive.sh
RUN chmod +x /keepalive.sh

EXPOSE 8080 51820/udp

CMD ["/entrypoint.sh"]