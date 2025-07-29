ARG BUILD_ARCH
FROM mvance/unbound:latest

# mvance/unbound images are based on alpine:
RUN apk add --no-cache curl

# Download and install bashio
ARG BASHIO_VERSION=2024.08.0
RUN curl -sL https://github.com/home-assistant/bashio/releases/download/${BASHIO_VERSION}/bashio \
    -o /usr/bin/bashio \
    && chmod a+x /usr/bin/bashio

# Copy your run.sh script into the container and make it executable
COPY run.sh /usr/bin/run.sh
RUN chmod a+x /usr/bin/run.sh

# This Dockerfile relies on mvance/unbound's own ENTRYPOINT (which runs unbound).
# Your run.sh will be executed *before* that main entrypoint via S6-Overlay.
# Therefore, you do NOT need to install S6-Overlay in the Dockerfile itself.
# Home Assistant Supervisor's underlying Docker environment will wrap this with S6.

# Set a custom ENTRYPOINT for the container that runs bashio before the main unbound process.
# This assumes that the mvance/unbound image doesn't strictly override ENTRYPOINT,
# or that bashio can properly launch unbound in the foreground.
# Let's use the standard HA init structure.

# The original mvance/unbound image likely has its own ENTRYPOINT that starts Unbound.
# If we install S6-Overlay, it will replace that.
# Let's go back to the idea that mvance/unbound is mostly ready.

# Simpler Dockerfile, with just bashio install.
# If mvance/unbound does indeed have /bin/sh or /bin/bash, this should work.
# The error "apk not found" means it's NOT Alpine, or the PATH is weird.

# If `apk` is not found, then it's NOT alpine, it's something else like Debian or Ubuntu-based, or distroless.
# If it's distroless, we're back to the multi-stage copy.
# If it's Debian/Ubuntu, then `apt-get` is needed.

**This error `apk: not found` means `mvance/unbound` is NOT Alpine-based, or is so minimal it removed `apk`.** This drastically changes things. It's almost certainly `debian`-based, or a custom build.

**Let's assume it's Debian/Ubuntu based and contains `curl` and `tar` (likely):**

```dockerfile
ARG BUILD_ARCH
FROM mvance/unbound:latest

# Install necessary tools for bashio (curl, if not present already).
# If mvance/unbound is Debian/Ubuntu based, it uses apt.
# If it's truly distroless and has no package manager, then this path is impossible.
# Let's try `apt-get`.
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates && rm -rf /var/lib/apt/lists/*

# Download and install bashio
ARG BASHIO_VERSION=2024.08.0
RUN curl -sL [https://github.com/home-assistant/bashio/releases/download/$](https://github.com/home-assistant/bashio/releases/download/$){BASHIO_VERSION}/bashio \
    -o /usr/bin/bashio \
    && chmod a+x /usr/bin/bashio

# Copy your run.sh script into the container and make it executable
COPY run.sh /usr/bin/run.sh
RUN chmod a+x /usr/bin/run.sh

# mvance/unbound doesn't use S6-Overlay, so we need to add it just like before.
# This implies the image DOES have /bin/sh or /bin/bash, contrary to the previous Alpine theory.
# The previous `apk: not found` strongly implies it's Debian/Ubuntu.

ARG S6_OVERLAY_VERSION=3.1.6.2
RUN curl -sSL [https://github.com/just-containers/s6-overlay/releases/download/v$](https://github.com/just-containers/s6-overlay/releases/download/v$){S6_OVERLAY_VERSION}/s6-overlay-${BUILD_ARCH}.tar.xz \
    -o /tmp/s6-overlay.tar.xz \
    && tar -C / -Jxpf /tmp/s6-overlay.tar.xz \
    && rm /tmp/s6-overlay.tar.xz

# Set the ENTRYPOINT to S6-Overlay's init system
ENTRYPOINT ["/init"]
CMD ["/usr/bin/bashio", "/usr/bin/run.sh"]

# Expose ports as declared in config.json
EXPOSE 54/tcp 54/udp
