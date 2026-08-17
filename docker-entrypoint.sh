#!/usr/bin/env bash
set -e

# Ensure data directories exist
mkdir -p /etc/vpn-ui /root/cert /var/log/vpn-ui /usr/local/vpn-ui/bin

# Start fail2ban if requested
if [ "${XUI_ENABLE_FAIL2BAN:-false}" = "true" ] || [ "${VPNUI_ENABLE_FAIL2BAN:-false}" = "true" ]; then
    if command -v fail2ban-server >/dev/null 2>&1; then
        echo "[vpn-ui] Starting fail2ban service..."
        fail2ban-client -x start >/dev/null 2>&1 || true
    fi
fi

# Optional first-run parameter configuration
if [ -n "${VPNUI_PORT:-}" ] || [ -n "${VPNUI_USER:-}" ] || [ -n "${VPNUI_PASSWORD:-}" ] || [ -n "${VPNUI_PATH:-}" ]; then
    ARGS=()
    [ -n "${VPNUI_PORT:-}" ] && ARGS+=("--port" "${VPNUI_PORT}")
    [ -n "${VPNUI_USER:-}" ] && ARGS+=("--user" "${VPNUI_USER}")
    [ -n "${VPNUI_PASSWORD:-}" ] && ARGS+=("--pass" "${VPNUI_PASSWORD}")
    [ -n "${VPNUI_PATH:-}" ] && ARGS+=("--path" "${VPNUI_PATH}")

    # If the database doesn't exist yet, apply the explicit setup flags
    if [ ! -f "/etc/vpn-ui/vpn-ui.db" ] && [ ! -f "/etc/vpn-ui/x-ui.db" ]; then
        echo "[vpn-ui] Initializing panel with custom settings: ${ARGS[*]}"
        /usr/local/vpn-ui/vpn-ui "${ARGS[@]}" >/dev/null 2>&1 || true
    fi
fi

# Execute main process
echo "[vpn-ui] Starting vpn-ui server..."
exec "$@"
