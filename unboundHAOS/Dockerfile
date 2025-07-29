# Stage 1: Build Environment - Use alpinelinux/unbound as base to install HA components
ARG BUILD_ARCH
FROM alpinelinux/unbound:latest AS build_env

# Ensure necessary tools are available for downloads and package management.
# alpinelinux/unbound is Alpine-based, so apk is the package manager.
# curl, bash, xz, tar are needed for bashio/S6-Overlay setup.
RUN apk update && apk add --no-cache curl bash xz tar && rm -rf /var/cache/apk/*

# --- Download and install bashio ---
ARG BASHIO_VERSION=2024.08.0
RUN curl -sL https://github.com/home-assistant/bashio/releases/download/${BASHIO_VERSION}/bashio \
    -o /usr/bin/bashio \
    && chmod a+x /usr/bin/bashio

# --- Install S6-Overlay (required for Home Assistant Add-ons) ---
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


# Stage 2: Final Add-on Image - Build on the now S6-Overlay/bashio-enabled image
FROM build_env

# Set a basic PATH (as a safeguard)
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# --- Copy your run.sh script and define S6 service ---
# Create the service directory
RUN mkdir -p /etc/services.d/unbound-starter

# Copy the run.sh script to be the S6 service run script
COPY run.sh /etc/services.d/unbound-starter/run
RUN chmod a+x /etc/services.d/unbound-starter/run

# Set the ENTRYPOINT to S6-Overlay's init system
ENTRYPOINT ["/init"]
CMD [] # CMD is empty, as S6 will manage services

# Expose ports as declared in config.json
EXPOSE 54/tcp 54/udp
