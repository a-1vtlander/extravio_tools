# Common functions for routing scripts

# Simple debug logger (prints to stderr when EXTRAVIO_DEBUG=yes)
log_debug() {
    if [ "${EXTRAVIO_DEBUG:-no}" = "yes" ]; then
        echo "[extravio] debug: $*" >&2
    fi
}

# Assert helper for programmer-facing invariants. Prints a BUG message and exits.
ASSERT() {
    if [ "$#" -gt 0 ]; then
        echo "[extravio] BUG: $*" >&2
    else
        echo "[extravio] BUG: assertion failed" >&2
    fi
    exit 2
}

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

# Check whether a host (hostname or IP) resolves locally (no VPN required).
# Returns 0 if the host resolves to an IP locally (via getent/host/dig/nslookup), 1 otherwise.
check_host_resolution() {
    local h="$1"
    if [ -z "$h" ]; then
        return 1
    fi
    # Simple reachability probe: try a single ping. Treat success as reachable
    # (no VPN required). This is portable across POSIX systems.
    if ping -c 1 "$h" >/dev/null 2>&1; then
        log_debug "ping to '$h' succeeded"
        return 0
    else
        log_debug "ping to '$h' failed"
        return 1
    fi
}

ensure_host_reachability_if_tailscale_required() {
    # Usage: ensure_host_reachability_if_tailscale_required <needs_ts: yes|no> <host>
    local needs_ts="$1"
    local host="$2"

    # If route does not require tailscale, nothing to do
    if [ "$needs_ts" != "yes" ]; then
        log_debug "tailscale not required by route (needs_ts=$needs_ts)"
        return 0
    fi

    if [ -z "$host" ]; then
        ASSERT "ensure_host_reachability_if_tailscale_required requires a host parameter — caller bug"
    fi

    # If host is reachable locally, skip starting tailscale
    if check_host_resolution "$host"; then
        log_debug "host '$host' reachable locally; skipping tailscale"
        return 0
    fi

    # Start tailscale if not already running
    local ts_status
    ts_status=$(tailscale status --json 2>/dev/null | jq -r '.BackendState // "Unknown"' 2>/dev/null || echo "Unknown")
    if [ "$ts_status" != "Running" ]; then
        echo
        echo "-> Ensuring Tailscale is active..."
        tailscale up
    else
        log_debug "Tailscale already running"
    fi
}


# Return a newline-separated list of currently-connected Wi-Fi SSIDs (best-effort)
get_connected_wifi_ssids() {
    # macOS: try airport utility, fallback to networksetup
    if [[ "$(uname)" == "Darwin" ]]; then
        if [ -x "/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport" ]; then
            log_debug "trying airport utility for SSID"
            /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I 2>/dev/null | awk -F": " '/ SSID/ {print $2; exit}'
            ret=$?
            log_debug "airport returned exit:$ret"
            return $ret
        fi
        if command -v networksetup >/dev/null 2>&1; then
            log_debug "trying networksetup to find Wi-Fi interface"
            # try common interfaces, falling back to discovering the interface could be added later
            for iface in en0 en1; do
                ssid=$(networksetup -getairportnetwork "$iface" 2>/dev/null || true)
                if [[ "$ssid" =~ :[[:space:]](.+) ]]; then
                    echo "${BASH_REMATCH[1]}"
                    log_debug "networksetup found SSID '${BASH_REMATCH[1]}' on $iface"
                    return 0
                fi
            done
            log_debug "networksetup did not find SSID on en0/en1"
            return 1
        fi
    else
        # Linux: prefer nmcli, fallback to iwgetid
        if command -v nmcli >/dev/null 2>&1; then
            log_debug "trying nmcli for SSID"
            nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | awk -F: '$1=="yes"{print $2}'
            ret=$?
            log_debug "nmcli exit:$ret"
            return $ret
        fi
        if command -v iwgetid >/dev/null 2>&1; then
            log_debug "trying iwgetid for SSID"
            iwgetid -r 2>/dev/null
            ret=$?
            log_debug "iwgetid exit:$ret"
            return $ret
        fi
    fi

    return 1
}


# Determine whether tailscale is required for a given route alias.
# Returns 'yes' if tailscale should be used, 'no' otherwise.
reachable_via_tailscale_for_alias() {
    local alias="$1"
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local routes_json="$script_dir/routes.json"

    if [ ! -f "$routes_json" ]; then
        log_debug "routes.json not found at $routes_json"
        echo "yes"
        return 0
    fi

    if ! command -v jq >/dev/null 2>&1; then
        # If jq not available, fall back to reading reachable_via_tailscale field via grep (best-effort)
        local tr
        tr=$(grep -oP '(?<="'$alias'"\s*:\s*\{[^}]*"reachable_via_tailscale"\s*:\s*\")\w+' "$routes_json" 2>/dev/null || true)
        tr=${tr:-yes}
        echo "$tr"
        return 0
    fi

    local reachable_via_tailscale
    reachable_via_tailscale=$(jq -r --arg alias "$alias" '.[$alias].reachable_via_tailscale // "no"' "$routes_json")
    log_debug "route '$alias' reachable_via_tailscale='$reachable_via_tailscale'"

    if [ "$reachable_via_tailscale" != "yes" ]; then
        log_debug "route '$alias' does not require Tailscale"
        echo "no"
        return 0
    fi

    # If a local_wifi is specified for this route, check if currently connected to it
    local local_wifi
    local_wifi=$(jq -r --arg alias "$alias" '.[$alias].local_wifi // empty' "$routes_json")
    log_debug "route '$alias' local_wifi='$local_wifi'"
    if [ -z "$local_wifi" ]; then
        echo "yes"
        return 0
    fi

    # Check connected SSIDs
    if ssids=$(get_connected_wifi_ssids 2>/dev/null); then
        log_debug "detected SSIDs:\n$ssids"
        while IFS= read -r s; do
            if [ "$s" = "$local_wifi" ]; then
                log_debug "connected to local_wifi '$local_wifi' -> tailscale not required"
                echo "no"
                return 0
            fi
        done <<< "$ssids"
    else
        log_debug "get_connected_wifi_ssids failed or returned nothing"
    fi

    echo "yes"
    return 0
}
