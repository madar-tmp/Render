FROM debian:bullseye-slim

# Set environment defaults
ENV TAILSCALE_HOSTNAME="render-server-surya"
ENV TAILSCALE_ADDITIONAL_ARGS=""

# Fix sources for archived bullseye and install required tools
RUN echo "deb http://archive.debian.org/debian bullseye main" > /etc/apt/sources.list && \
    echo "deb http://archive.debian.org/debian-security bullseye-security main" >> /etc/apt/sources.list && \
    apt-get -o Acquire::Check-Valid-Until=false update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        wget \
        python3 \
        jq \
    && rm -rf /var/lib/apt/lists/*

# Install Tailscale
RUN curl -fsSL https://tailscale.com/install.sh | sh

# Create necessary directories
RUN mkdir -p /var/run/tailscale /var/cache/tailscale /var/lib/tailscale /tmp

WORKDIR /tailscale.d
COPY start.sh /tailscale.d/start.sh
RUN chmod +x /tailscale.d/start.sh

CMD ["./start.sh"]