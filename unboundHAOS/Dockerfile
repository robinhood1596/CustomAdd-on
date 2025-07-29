ARG BUILD_ARCH
FROM mvance/unbound:latest

# Install necessary tools for bashio (curl, if not present already).
# mvance/unbound is likely Debian/Ubuntu based, so it uses apt.
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates && rm -rf /var/lib/apt/lists/*

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
RUN curl -sSL https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${BUILD_ARCH}.tar.xz \
    -o /tmp/s6-overlay.tar.xz \
    && tar -C / -Jxpf /tmp/s6-overlay.tar.xz \
    && rm /tmp/s6-overlay.tar.xz

# Set the ENTRYPOINT to S6-Overlay's init system
ENTRYPOINT ["/init"]
CMD ["/usr/bin/bashio", "/usr/bin/run.sh"]

# Expose ports as declared in config.json
EXPOSE 54/tcp 54/udp
