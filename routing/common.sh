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
    if [ "$needs_ts" = "yes" ]; then
        echo 
        echo "-> Ensuring Tailscale is active..."
        tailscale up
    fi
}