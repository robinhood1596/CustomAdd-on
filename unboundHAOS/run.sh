#!/usr/bin/with-contenv bashio
# This shebang ensures bashio is loaded

bashio::log.info "Starting Unbound Add-on..."

# --- Read configuration options from config.json ---
UNBOUND_PORT=$(bashio::config 'unbound_listen_port')
UNBOUND_VERBOSITY=$(bashio::config 'unbound_verbosity')
ACCESS_CONTROL_IPS=$(bashio::config 'access_control_ips')

# --- Generate unbound.conf ---
# Unbound expects its config at /etc/unbound/unbound.conf usually,
# or in /opt/unbound/etc/unbound/ for klutchell/unbound
CONFIG_DIR="/etc/unbound" # Default for most Unbound installations
# If using klutchell/unbound image base, adjust to:
# CONFIG_DIR="/opt/unbound/etc/unbound"

mkdir -p "${CONFIG_DIR}" # Ensure config directory exists
CONFIG_FILE="${CONFIG_DIR}/unbound.conf"

bashio::log.info "Generating Unbound configuration file: ${CONFIG_FILE}"

# Start writing the config file
cat > "${CONFIG_FILE}" <<EOF
server:
    port: ${UNBOUND_PORT}
    interface: 0.0.0.0 # Listen on all IPv4 interfaces
    do-ip4: yes
    do-udp: yes
    do-tcp: yes

    # Allow queries from specified IP ranges
    # Note: bashio::config returns a JSON array, we need to loop or parse.
    # For a simple string input (e.g., "192.168.178.0/24,10.0.0.0/8") use:
    # ACCESS_CONTROL_IPS_STR=$(bashio::config 'access_control_ips')
    # IFS=',' read -ra ADDR <<< "$ACCESS_CONTROL_IPS_STR"
    # for i in "${ADDR[@]}"; do
    #    echo "    access-control: $i allow" >> "${CONFIG_FILE}"
    # done
    #
    # If using array of strings (as defined in config.json schema for 'access_control_ips'):
    $(bashio::jq "${CONFIG_PATH}" '.access_control_ips[] | "- access-control: " + . + " allow"')

    logfile: ""        # Log to stdout/stderr
    use-syslog: no     # Do not use syslog inside container
    verbosity: ${UNBOUND_VERBOSITY}

    # Recommended DNSSEC setup
    auto-trust-anchor-file: "/var/lib/unbound/root.key" # Common path for root.key

    # Optional: Other useful settings
    # hide-version: yes
    # harden-glue: yes
    # harden-dnssec-stripped: yes
    # module-config: "validator iterator"
EOF

bashio::log.info "Unbound configuration generated."
cat "${CONFIG_FILE}" # Log the generated config for debugging

# --- Handle root.key for DNSSEC ---
ROOT_KEY_PATH="/var/lib/unbound/root.key" # Common path for root.key, consistent with auto-trust-anchor-file

# If root.key doesn't exist, fetch it for initial setup
if [ ! -f "${ROOT_KEY_PATH}" ]; then
    bashio::log.info "Downloading initial root.key for DNSSEC..."
    # You might need to install 'wget' or 'curl' in your Dockerfile if not present
    wget -O "${ROOT_KEY_PATH}" https://www.internic.net/domain/named.cache || \
    bashio::log.error "Failed to download root.key. DNSSEC might not work."
else
    bashio::log.info "root.key already exists."
fi

# Set permissions for the root.key file if needed
chmod 644 "${ROOT_KEY_PATH}"

# --- Start Unbound ---
bashio::log.info "Starting Unbound daemon..."
# -dv for daemon mode and verbose to stdout (if logfile is "")
exec /usr/sbin/unbound -c "${CONFIG_FILE}" -dv
