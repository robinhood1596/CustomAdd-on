#!/usr/bin/with-contenv bashio
# This shebang ensures bashio is loaded for Home Assistant Add-ons

# Exit immediately if a command exits with a non-zero status.
set -e

bashio::log.info "Starting Unbound Add-on (mvance)..."

# --- Define Paths ---
# mvance/unbound uses /etc/unbound/unbound.conf and /etc/unbound/unbound.conf.d/
UNBOUND_CONFIG_DIR="/etc/unbound"
UNBOUND_ROOT_KEY_PATH="/etc/unbound/root.key" # mvance/unbound expects root.key here
UNBOUND_CONF_D_DIR="${UNBOUND_CONFIG_DIR}/unbound.conf.d" # For custom configs

# --- Read configuration options from config.json ---
UNBOUND_PORT=$(bashio::config 'listen_port')
UNBOUND_VERBOSITY=$(bashio::config 'verbosity')
bashio::log.info "Configured port: ${UNBOUND_PORT}, Verbosity: ${UNBOUND_VERBOSITY}"

# --- Generate dynamic Unbound configuration snippets ---
bashio::log.info "Generating dynamic Unbound configuration snippets in ${UNBOUND_CONF_D_DIR}"
mkdir -p "${UNBOUND_CONF_D_DIR}" || bashio::log.fatal "Failed to create config directory: ${UNBOUND_CONF_D_DIR}"

# Create a port and interface config file
cat > "${UNBOUND_CONF_D_DIR}/port.conf" <<EOF
server:
    port: ${UNBOUND_PORT}
    interface: 0.0.0.0
    do-ip4: yes
    do-udp: yes
    do-tcp: yes
    verbosity: ${UNBOUND_VERBOSITY}
    # These are defaults in mvance/unbound, but explicit is fine
    # auto-trust-anchor-file: "${UNBOUND_ROOT_KEY_PATH}"
    # module-config: "validator iterator"
EOF

# Create access control file
cat > "${UNBOUND_CONF_D_DIR}/access-control.conf" <<EOF
server:
EOF

bashio::log.info "Adding access-control rules..."
bashio::config | bashio::jq '.access_control_ips[] | "    access-control: " + . + " allow"' \
| while read -r line; do
    echo "${line}" >> "${UNBOUND_CONF_D_DIR}/access-control.conf"
done
bashio::log.info "Access-control rules added."

# --- Handle root.key for DNSSEC ---
bashio::log.info "Handling root.key for DNSSEC..."
# mvance/unbound includes unbound-anchor and it's usually run by its entrypoint.
# We ensure the root.key is present and updated explicitly if needed.
# The `mvance/unbound` image's `docker-entrypoint.sh` might already handle this.
# Let's ensure our `run.sh` doesn't conflict or duplicate.
# For simplicity, we'll let mvance/unbound's entrypoint manage the initial root.key setup.
# We'll just ensure the file exists and has permissions if the base image relies on it.

# Ensure the directory for root.key exists (if it's not already by mvance/unbound)
mkdir -p "$(dirname "${UNBOUND_ROOT_KEY_PATH}")"

# Run unbound-anchor explicitly if the base image's entrypoint doesn't
# or if we want to force an update.
# This assumes /usr/sbin/unbound-anchor is available and in PATH.
# mvance/unbound usually puts it in /usr/sbin.
if [ ! -f "${UNBOUND_ROOT_KEY_PATH}" ]; then
    bashio::log.info "Root key not found. Attempting initial setup with unbound-anchor."
    /usr/sbin/unbound-anchor -a "${UNBOUND_ROOT_KEY_PATH}" || \
    bashio::log.error "Failed to generate initial root.key with unbound-anchor. DNSSEC might fail."
else
    bashio::log.info "Root key exists. Updating it with unbound-anchor."
    /usr/sbin/unbound-anchor -a "${UNBOUND_ROOT_KEY_PATH}" || \
    bashio::log.error "Failed to update root.key with unbound-anchor. DNSSEC might fail."
fi

chmod 644 "${UNBOUND_ROOT_KEY_PATH}"
bashio::log.info "Permissions set for root.key."

# mvance/unbound expects the unbound daemon to be started by its own entrypoint.
# We just need to make sure our configuration files are in place.
bashio::log.info "Unbound configuration prepared. mvance/unbound's entrypoint will start the daemon."

# Since mvance/unbound's entrypoint will eventually run `unbound`,
# we need to ensure this script doesn't just exit.
# A common pattern is to make this script the "pre-run" and then let
# the actual application take over.
# If /init calls us, and we exit, the container exits.
# So, we should *not* `exec` unbound directly here.
# Instead, we rely on the mvance/unbound image's own entrypoint to run unbound
# after our configuration snippets are placed.

# The /init (s6-overlay) entrypoint runs /usr/bin/bashio /usr/bin/run.sh.
# Once run.sh completes, if nothing else keeps the container alive, it exits.
# We need to tell s6-overlay to run unbound as its main service.

# This implies we need an s6 service file.

# Instead of relying on mvance/unbound's *internal* entrypoint for unbound,
# which might be complex, let's just directly launch unbound from our script,
# leveraging the fact that mvance/unbound has all the binaries and dependencies.
bashio::log.info "Starting Unbound daemon directly..."
exec /usr/sbin/unbound -c "${UNBOUND_CONFIG_DIR}/unbound.conf" -dv
# Note: mvance/unbound's unbound.conf includes `include-dir: /etc/unbound/unbound.conf.d`.
# This will automatically pick up our generated config snippets.
