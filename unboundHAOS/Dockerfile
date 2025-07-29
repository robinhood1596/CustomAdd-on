ARG BUILD_ARCH
FROM mvance/unbound:latest

# Install necessary tools: curl for downloading, ca-certificates for HTTPS, xz-utils for .xz decompression, and tar for archives.
# Also add 'bash' for run.sh consistency, as it's often better than default /bin/sh.
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates xz-utils tar bash && rm -rf /var/lib/apt/lists/*

# Download and install bashio
ARG BASHIO_VERSION=2024.08.0
RUN curl -sL https://github.com/home-assistant/bashio/releases/download/${BASHIO_VERSION}/bashio \
    -o /usr/bin/bashio \
    && chmod a+x /usr/bin/bashio

# Copy your run.sh script into the container and make it executable
COPY run.sh /usr/bin/run.sh
RUN chmod a+x /usr/bin/run.sh

# Install S6-Overlay (required for Home Assistant Add-ons)
ARG S6_OVERLAY_VERSION=3.1.6.2

# Handle potential BUILD_ARCH to S6-Overlay arch mapping
# Example: Home Assistant's amd64 maps to s6-overlay's x86_64
# For aarch64, it's typically aarch64.
# Let's map for common cases:
RUN S6_ARCH="${BUILD_ARCH}"; \
    if [ "$BUILD_ARCH" = "amd64" ]; then S6_ARCH="x86_64"; fi; \
    if [ "$BUILD_ARCH" = "armv7" ]; then S6_ARCH="arm"; fi; \
    if [ "$BUILD_ARCH" = "aarch64" ]; then S6_ARCH="aarch64"; fi; \
    if [ "$BUILD_ARCH" = "armhf" ]; then S6_ARCH="armhf"; fi; \
    \
    bashio::log.info "Downloading s6-overlay-noarch.tar.xz..."; \
    curl -sSL https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz \
    -o /tmp/s6-overlay-noarch.tar.xz; \
    \
    bashio::log.info "Downloading s6-overlay-${S6_ARCH}.tar.xz..."; \
    curl -sSL https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_ARCH}.tar.xz \
    -o /tmp/s6-overlay-arch.tar.xz; \
    \
    bashio::log.info "Extracting S6-Overlay..."; \
    tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz \
    && tar -C / -Jxpf /tmp/s6-overlay-arch.tar.xz; \
    \
    bashio::log.info "Cleaning up S6-Overlay downloads..."; \
    rm /tmp/s6-overlay-noarch.tar.xz /tmp/s6-overlay-arch.tar.xz

# Set the ENTRYPOINT to S6-Overlay's init system
ENTRYPOINT ["/init"]
CMD ["/usr/bin/bashio", "/usr/bin/run.sh"]

# Expose ports as declared in config.json
EXPOSE 54/tcp 54/udp
