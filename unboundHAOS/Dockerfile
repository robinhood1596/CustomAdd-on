ARG BUILD_ARCH
FROM mvance/unbound:latest

# Install necessary tools: curl, ca-certificates, xz-utils, tar, and bash.
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates xz-utils tar bash && rm -rf /var/lib/apt/lists/*

# Download and install bashio
ARG BASHIO_VERSION=2024.08.0
RUN curl -sL https://github.com/home-assistant/bashio/releases/download/${BASHIO_VERSION}/bashio \
    -o /usr/bin/bashio \
    && chmod a+x /usr/bin/bashio

# Copy your run.sh script into the container and make it executable
COPY run.sh /usr/bin/run.sh
RUN chmod a+x /usr/bin/run.sh

# Install S6-Overlay (required for Home Assistant Add-ons) - Rely on /init directly
ARG S6_OVERLAY_VERSION=3.1.6.2

# Handle potential BUILD_ARCH to S6-Overlay arch mapping
RUN S6_ARCH="${BUILD_ARCH}"; \
    if [ "$BUILD_ARCH" = "amd64" ]; then S6_ARCH="x86_64"; fi; \
    if [ "$BUILD_ARCH" = "armv7" ]; then S6_ARCH="arm"; fi; \
    if [ "$BUILD_ARCH" = "aarch64" ]; then S6_ARCH="aarch64"; fi; \
    if [ "$BUILD_ARCH" = "armhf" ]; then S6_ARCH="armhf"; fi; \
    \
    echo "Downloading s6-overlay-noarch.tar.xz..."; \
    curl -sSL https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz \
    -o /tmp/s6-overlay-noarch.tar.xz; \
    \
    echo "Downloading s6-overlay-${S6_ARCH}.tar.xz..."; \
    curl -sSL https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_ARCH}.tar.xz \
    -o /tmp/s6-overlay-arch.tar.xz; \
    \
    echo "Extracting S6-Overlay..."; \
    tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz \
    && tar -C / -Jxpf /tmp/s6-overlay-arch.tar.xz; \
    \
    echo "Cleaning up S6-Overlay downloads..."; \
    rm /tmp/s6-overlay-noarch.tar.xz /tmp/s6-overlay-arch.tar.xz

# Set a basic PATH (as a safeguard) - might not be needed but harmless
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# --- S6 Service Definition for your run.sh script ---
# Create the service directory
RUN mkdir -p /etc/services.d/unbound-starter

# Copy the run script for the S6 service
COPY run.sh /etc/services.d/unbound-starter/run
RUN chmod a+x /etc/services.d/unbound-starter/run

# Set the ENTRYPOINT to S6-Overlay's init system
ENTRYPOINT ["/init"] # This is the standard S6-Overlay entrypoint
CMD [] # CMD is empty, as S6 will manage services

# Expose ports as declared in config.json
EXPOSE 54/tcp 54/udp
