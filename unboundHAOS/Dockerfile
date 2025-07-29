# Stage 0: Extract Unbound binaries and essential files from mvance/unbound
FROM mvance/unbound:latest AS unbound_source

# Stage 1: Build Environment - A robust Alpine image for building and preparing
FROM alpine:latest AS build_env

# Ensure bash is present for later script execution if needed, and curl/tar for downloads
RUN apk add --no-cache curl bash tar xz

# --- Download/Extract S6-Overlay ---
ARG BUILD_ARCH
ARG S6_OVERLAY_VERSION=3.1.6.2
RUN curl -sSL https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${BUILD_ARCH}.tar.xz \
    -o /tmp/s6-overlay.tar.xz \
    && mkdir -p /s6-overlay \
    && tar -C /s6-overlay -Jxpf /tmp/s6-overlay.tar.xz \
    && rm /tmp/s6-overlay.tar.xz

# --- Download/Extract bashio ---
ARG BASHIO_VERSION=2024.08.0
RUN curl -sL https://github.com/home-assistant/bashio/releases/download/${BASHIO_VERSION}/bashio \
    -o /usr/bin/bashio \
    && chmod a+x /usr/bin/bashio

# --- Copy your run.sh script and make it executable ---
COPY run.sh /usr/bin/run.sh
RUN chmod a+x /usr/bin/run.sh


# Stage 2: Final Add-on Image - A clean Alpine base with all components
FROM alpine:latest

# --- Copy S6-Overlay files from build_env ---
COPY --from=build_env /s6-overlay /

# --- Copy bashio from build_env ---
COPY --from=build_env /usr/bin/bashio /usr/bin/bashio

# --- Copy Unbound binaries and essential files from unbound_source ---
# This assumes the locations within mvance/unbound:latest
COPY --from=unbound_source /usr/sbin/unbound /usr/sbin/unbound
COPY --from=unbound_source /usr/sbin/unbound-anchor /usr/sbin/unbound-anchor
# Copy any default configuration files or hints from mvance/unbound
COPY --from=unbound_source /etc/unbound /etc/unbound # Copies the whole default /etc/unbound

# Ensure the copied binaries are executable (might already be, but safe to repeat)
RUN chmod a+x /usr/sbin/unbound /usr/sbin/unbound-anchor

# --- Copy the prepared run.sh from build_env ---
COPY --from=build_env /usr/bin/run.sh /usr/bin/run.sh

# Ensure necessary runtime directories exist for Unbound (if not covered by /etc/unbound copy)
RUN mkdir -p /var/lib/unbound

# Set the correct S6-Overlay ENTRYPOINT for Home Assistant Add-ons
ENTRYPOINT ["/init"]
CMD ["/usr/bin/bashio", "/usr/bin/run.sh"]

# Expose ports as declared in config.json
EXPOSE 54/tcp 54/udp
