#!/usr/bin/with-contenv bashio
# This shebang ensures bashio is loaded for Home Assistant Add-ons

# Exit immediately if a command exits with a non-zero status.
set -e

bashio::log.info "Starting Unbound Add-on..."

# --- Define Paths ---
UNBOUND_CONFIG_DIR="/etc/unbound"             # Standard config dir within klutchell/unbound image
UNBOUND_CONFIG_FILE="${UNBOUND_CONFIG_DIR}/unbound.conf"
UNBOUND_ROOT_KEY_PATH="/var/lib/unbound/root.key" # Standard path for root.key in klutchell/unbound

bashio::log.info "Reading configuration options from config.json..."
# --- Read configuration options from config.json ---
UNBOUND_PORT=$(bashio::config 'listen_port')
UNBOUND_VERBOSITY=$(bashio::config 'verbosity')
bashio::log.info "Configured port: ${UNBOUND_PORT}, Verbosity: ${UNBOUND_VERBOSITY}"


bashio::log.info "Generating Unbound configuration file: ${UNBOUND_CONFIG_FILE}"

# --- Create configuration directory if it doesn't exist ---
mkdir -p "${UNBOUND_CONFIG_DIR}" || bashio::log.fatal "Failed to create config directory: ${UNBOUND_CONFIG_DIR}"
bashio::log.info "Configuration directory created/ensured."

# --- Start writing the config file ---
cat > "${UNBOUND_CONFIG_FILE}" <<EOF
server:
    port: ${UNBOUND_PORT}
    interface: 0.0.0.0 # Listen on all IPv4 interfaces
    do-ip4: yes
    do-udp: yes
    do-tcp: yes

    # Allow queries from specified IP ranges (parsed from config.json)
EOF
bashio::log.info "Base config written."

# Add access-control lines based on the array from config.json
bashio::log.info "Adding access-control rules..."
bashio::config | bashio::jq '.access_control_ips[] | "- access-control: " + . + " allow"' \
| while read -r line; do
    echo "    ${line}" >> "${UNBOUND_CONFIG_FILE}"
done
bashio::log.info "Access-control rules added."


# Continue writing the config file after access-control rules
cat >> "${UNBOUND_CONFIG_FILE}" <<EOF
    logfile: ""        # Log to stdout/stderr (crucial for docker logs)
    use-syslog: no     # Do not use syslog inside container

    verbosity: ${UNBOUND_VERBOSITY}

    # Recommended DNSSEC setup - klutchell/unbound includes tools for this
    auto-trust-anchor-file: "${UNBOUND_ROOT_KEY_PATH}"

    # Optional: Other useful settings
    # hide-version: yes
    # harden-glue: yes
    # harden-dnssec-stripped: yes
    # module-config: "validator iterator" # Default for klutchell/unbound, can be explicit
EOF
bashio::log.info "Final config sections written."

bashio::log.info "Unbound configuration generated. Content:"
cat "${UNBOUND_CONFIG_FILE}" # Log the generated config for debugging

# --- Handle root.key for DNSSEC ---
bashio::log.info "Handling root.key for DNSSEC..."
mkdir -p "$(dirname "${UNBOUND_ROOT_KEY_PATH}")" # Ensure directory for root.key exists
bashio::log.info "Root key directory created/ensured."

if [ ! -f "${UNBOUND_ROOT_KEY_PATH}" ]; then
    bashio::log.info "Root key not found. Attempting initial setup with unbound-anchor."
    # Use unbound-anchor to fetch/update the root trust anchor
    # Ensure unbound-anchor is in the PATH or provide full path
    /usr/sbin/unbound-anchor -v -a "${UNBOUND_ROOT_KEY_PATH}" || \
    bashio::log.error "Failed to generate initial root.key with unbound-anchor. DNSSEC might fail."
else
    bashio::log.info "Root key exists. Updating it with unbound-anchor."
    /usr/sbin/unbound-anchor -v -a "${UNBOUND_ROOT_KEY_PATH}" || \
    bashio::log.error "Failed to update root.key with unbound-anchor. DNSSEC might fail."
fi
bashio::log.info "Root key handling complete."

# Set correct permissions for the root.key file
chmod 644 "${UNBOUND_ROOT_KEY_PATH}"
bashio::log.info "Permissions set for root.key."

# --- Start Unbound Daemon ---
bashio::log.info "Attempting to start Unbound daemon..."
# -c specifies the config file
# -d runs as a daemon (but keeps it in foreground for docker)
# -v for verbose output to stderr (when logfile is "")
exec /usr/sbin/unbound -c "${UNBOUND_CONFIG_FILE}" -dv
bashio::log.info "Unbound daemon started (if 'exec' works)." # This line will likely not be reached
