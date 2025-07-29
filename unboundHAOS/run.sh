#!/usr/bin/with-contenv bashio

# Get options from config.json (via /data/options.json)
UNBOUND_PORT=$(bashio::config 'unbound_listen_port')
UNBOUND_VERBOSITY=$(bashio::config 'unbound_verbosity')
UNBOUND_ACCESS_FROM=$(bashio::config 'unbound_access_from')

bashio::log.info "Starting Unbound on port ${UNBOUND_PORT} with verbosity ${UNBOUND_VERBOSITY}"

# Create the unbound.conf based on options
mkdir -p /opt/unbound/etc/unbound/ # Ensure directory exists
cat > /opt/unbound/etc/unbound/unbound.conf <<EOF
server:
    port: ${UNBOUND_PORT}
    interface: 0.0.0.0
    do-ip4: yes
    do-udp: yes
    do-tcp: yes
    access-control: ${UNBOUND_ACCESS_FROM} allow
    logfile: ""
    use-syslog: no
    verbosity: ${UNBOUND_VERBOSITY}
    auto-trust-anchor-file: "/opt/unbound/etc/unbound/root.key"
EOF

# Ensure root.key exists for DNSSEC (initial download if not present)
if [ ! -f /opt/unbound/etc/unbound/root.key ]; then
    bashio::log.info "Downloading initial root.key for DNSSEC..."
    wget -O /opt/unbound/etc/unbound/root.key https://www.internic.net/domain/named.cache
    # Unbound also has a mechanism to update this, but initial download is key.
fi


# Start Unbound daemon
/usr/sbin/unbound -c /opt/unbound/etc/unbound/unbound.conf -dv
