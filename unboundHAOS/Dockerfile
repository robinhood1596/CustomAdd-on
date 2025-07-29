# Stage 1: Build Stage - Use a base image with a shell to prepare files
FROM alpine:latest AS build_stage

# Install curl (needed to download bashio)
RUN apk add --no-cache curl

# Download bashio
ARG BASHIO_VERSION=2024.08.0  # Use a recent stable bashio version
RUN curl -sL https://github.com/home-assistant/bashio/releases/download/${BASHIO_VERSION}/bashio \
    -o /usr/bin/bashio \
    && chmod a+x /usr/bin/bashio

# Copy your run.sh script and make it executable
COPY run.sh /usr/bin/run.sh
RUN chmod a+x /usr/bin/run.sh


# Stage 2: Final Image Stage - Use the minimalist klutchell/unbound image
ARG BUILD_ARCH
FROM klutchell/unbound:latest

# Install S6-Overlay (required for Home Assistant Add-ons)
# Get the correct S6-Overlay URL for your architecture
# Note: Ensure S6_OVERLAY_VERSION is correct and supports your arch
ARG S6_OVERLAY_VERSION=3.1.6.2
RUN curl -sSL https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${BUILD_ARCH}.tar.xz \
    -o /tmp/s6-overlay.tar.xz \
    && tar -C / -Jxpf /tmp/s6-overlay.tar.xz \
    && rm /tmp/s6-overlay.tar.xz

# Copy bashio from the build_stage
COPY --from=build_stage /usr/bin/bashio /usr/bin/bashio

# Copy the prepared (executable) run.sh from the build_stage
COPY --from=build_stage /usr/bin/run.sh /usr/bin/run.sh

# Set the correct S6-Overlay ENTRYPOINT for Home Assistant Add-ons
# This makes S6-Overlay the main process, which then runs bashio and your script
ENTRYPOINT ["/init"]
CMD ["/usr/bin/bashio", "/usr/bin/run.sh"]

# Expose ports as declared in config.json (good practice)
EXPOSE 54/tcp 54/udp
