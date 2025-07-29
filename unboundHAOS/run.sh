#!/usr/bin/with-contenv bashio
# This shebang ensures bashio is loaded for Home Assistant Add-ons

# Exit immediately if a command exits with a non-zero status.
set -e

bashio::log.info "Starting Unbound Add-on (AlpineLinux)..."

# --- Define Paths ---
# Standard Alpine paths: binaries in /usr/sbin, config in /etc/unbound
UNBOUND_CONFIG_DIR="/etc/unbound"
UNBOUND_BIN_DIR="/usr/sbin" # Common path for unbound/unbound-anchor on Alpine
UNBOUND_ROOT_KEY_PATH="${UNBOUND_CONFIG_DIR}/root.key" # Common path for root.key

# Create config.d directory if needed (Unbound often auto-includes this)
UNBOUND_CONF_D_DIR="${UNBOUND_CONFIG_DIR}/unbound.conf.d"
mkdir -p "${UNBOUND_CONF_D_DIR}" || bashio::log.fatal "Failed to create config directory: ${UNBOUND_CONF_D_DIR}"

# --- Read configuration options from config.json ---
UNBOUND_PORT=$(bashio::config 'listen_port')
UNBOUND_VERBOSITY=$(bashio::config 'verbosity')
bashio::log.info "Configured port: ${UNBOUND_PORT}, Verbosity: ${UNBOUND_VERBOSITY}"

# --- Generate dynamic Unbound configuration snippets ---
bashio::log.info "Generating dynamic Unbound configuration snippets in ${UNBOUND_CONF_D_DIR}"

# Create a port and interface config file
cat > "${UNBOUND_CONF_D_DIR}/port.conf" <<EOF
server:
    port: ${UNBOUND_PORT}
    interface: 0.0.0.0
    do-ip4: yes
    do-udp: yes
    do-tcp: yes
    verbosity: ${UNBOUND_VERBOSITY}
    # Unbound typically loads root.key via auto-trust-anchor-file
    auto-trust-anchor-file: "${UNBOUND_ROOT_KEY_PATH}"
    # Default module config for validating resolver
    module-config: "validator iterator"
    # log-time-ascii: yes
    # log-queries: yes
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
# Ensure the directory for root.key exists
mkdir -p "$(dirname "${UNBOUND_ROOT_KEY_PATH}")"

# Use unbound-anchor to fetch/update the root trust anchor
# It should be in /usr/sbin/ on Alpine-based images.
if [ ! -f "${UNBOUND_ROOT_KEY_PATH}" ]; then
    bashio::log.info "Root key not found. Attempting initial setup with unbound-anchor."
    "${UNBOUND_BIN_DIR}/unbound-anchor" -a "${UNBOUND_ROOT_KEY_PATH}" || \
    bashio::log.error "Failed to generate initial root.key with unbound-anchor. DNSSEC might fail."
else
    bashio::log.info "Root key exists. Updating it with unbound-anchor."
    "${UNBOUND_BIN_DIR}/unbound-anchor" -a "${UNBOUND_ROOT_KEY_PATH}" || \
    bashio::log.error "Failed to update root.key with unbound-anchor. DNSSEC might fail."
fi

chmod 644 "${UNBOUND_ROOT_KEY_PATH}"
bashio::log.info "Permissions set for root.key."

bashio::log.info "Unbound configuration prepared. Starting Unbound daemon..."
# Unbound from Alpine packages typically uses /etc/unbound/unbound.conf
# which then includes /etc/unbound/unbound.conf.d/
exec "${UNBOUND_BIN_DIR}/unbound" -c "${UNBOUND_CONFIG_DIR}/unbound.conf" -dv
