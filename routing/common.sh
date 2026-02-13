# Common functions for routing scripts

ensure_ssh_agent() {
    if ! ssh-add -l >/dev/null 2>&1; then
        echo 
        echo "-> Starting ssh-agent..."
        eval "$(ssh-agent -s)"
        # Add all private keys corresponding to .pub files in ~/.ssh
        for pub in ~/.ssh/*.pub; do
            priv="${pub%.pub}"
            if [ -f "$priv" ]; then
                ssh-add "$priv"
            fi
        done
    fi
}

ensure_tailscale() {
    local needs_ts="$1"
    local disable_when_not_needed="${EXTRAVIO_DISABLE_TAILSCALE_WHEN_NOT_NEEDED:-no}"  # Environment variable control
    
    # Check current Tailscale status
    local ts_status
    ts_status=$(tailscale status --json 2>/dev/null | jq -r '.BackendState // "Unknown"' 2>/dev/null || echo "Unknown")
    
    if [ "$needs_ts" = "yes" ]; then
        if [ "$ts_status" != "Running" ]; then
            echo 
            echo "-> Ensuring Tailscale is active..."
            tailscale up
        fi
    else
        # Tailscale not required for this connection
        if [ "$ts_status" = "Running" ]; then
            if [ "$disable_when_not_needed" = "yes" ]; then
                echo 
                echo "-> Tailscale not required for this connection, disabling..."
                tailscale down
            else
                echo 
                echo "-> Note: Using local connection (Tailscale active but not required)"
            fi
        fi
    fi
}