#!/usr/bin/with-contenv bashio
# This shebang ensures bashio is loaded for Home Assistant Add-ons

bashio::log.info "Starting Unbound Add-on..."

# --- Define Paths ---
UNBOUND_CONFIG_DIR="/etc/unbound"          # Standard config dir within klutchell/unbound image
UNBOUND_CONFIG_FILE="${UNBOUND_CONFIG_DIR}/unbound.conf"
UNBOUND_ROOT_KEY_PATH="/var/lib/unbound/root.key" # Standard path for root.key in klutchell/unbound


# --- Read configuration options from config.json ---
UNBOUND_PORT=$(bashio::config 'listen_port')
UNBOUND_VERBOSITY=$(bashio::config 'verbosity')
# access_control_ips will be an array from config.json, we'll iterate it
# Example: "access_control_ips": ["192.168.1.0/24", "10.0.0.0/8"]

bashio::log.info "Generating Unbound configuration file: ${UNBOUND_CONFIG_FILE}"

# --- Create configuration directory if it doesn't exist ---
mkdir -p "${UNBOUND_CONFIG_DIR}" || bashio::log.fatal "Failed to create config directory: ${UNBOUND_CONFIG_DIR}"

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

# Add access-control lines based on the array from config.json
bashio::jq "${CONFIG_PATH}" '.access_control_ips[] | "- access-control: " + . + " allow"' \
| while read -r line; do
    echo "    ${line}" >> "${UNBOUND_CONFIG_FILE}"
done

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

bashio::log.info "Unbound configuration generated. Content:"
cat "${UNBOUND_CONFIG_FILE}" # Log the generated config for debugging

# --- Handle root.key for DNSSEC ---
# klutchell/unbound includes unbound-anchor and initial root.key during build.
# We ensure the root.key is present and update it.
mkdir -p "$(dirname "${UNBOUND_ROOT_KEY_PATH}")" # Ensure directory for root.key exists

if [ ! -f "${UNBOUND_ROOT_KEY_PATH}" ]; then
    bashio::log.info "Root key not found. Attempting initial setup with unbound-anchor."
    # Use unbound-anchor to fetch/update the root trust anchor
    # This might need /usr/sbin/unbound-anchor if it's not in PATH
    /usr/sbin/unbound-anchor -v -a "${UNBOUND_ROOT_KEY_PATH}" || \
    bashio::log.error "Failed to generate initial root.key with unbound-anchor. DNSSEC might fail."
else
    bashio::log.info "Root key exists. Updating it with unbound-anchor."
    # Regularly update the root trust anchor
    /usr/sbin/unbound-anchor -v -a "${UNBOUND_ROOT_KEY_PATH}" || \
    bashio::log.error "Failed to update root.key with unbound-anchor. DNSSEC might fail."
fi

# Set correct permissions for the root.key file
chmod 644 "${UNBOUND_ROOT_KEY_PATH}"

# --- Start Unbound Daemon ---
bashio::log.info "Starting Unbound daemon..."
# -c specifies the config file
# -d runs as a daemon
# -v for verbose output to stderr (when logfile is "")
exec /usr/sbin/unbound -c "${UNBOUND_CONFIG_FILE}" -dv
