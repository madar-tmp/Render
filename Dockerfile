FROM debian:bullseye-slim

# Set environment defaults
ENV TAILSCALE_HOSTNAME="render-vpn"
ENV TAILSCALE_ADDITIONAL_ARGS=""

# Install required tools
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    wget \
    # We keep iptables just in case, but we will use userspace-networking
    iptables \ 
    && rm -rf /var/lib/apt/lists/*

# Install Tailscale using the official script
RUN curl -fsSL https://tailscale.com/install.sh | sh

# Create necessary directories for Tailscale state
RUN mkdir -p /var/run/tailscale /var/cache/tailscale /var/lib/tailscale

WORKDIR /tailscale.d
COPY start.sh /tailscale.d/start.sh
RUN chmod +x /tailscale.d/start.sh

CMD ["./start.sh"]
