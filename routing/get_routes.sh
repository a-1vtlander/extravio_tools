#!/usr/bin/env bash

# Route configuration parser for JSON-based route definitions

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROUTES_JSON="$SCRIPT_DIR/routes.json"

# Check if jq is available
if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required to parse routes. Install with: brew install jq" >&2
    exit 1
fi

# Function to get address for a given alias
# Returns: user@host:needs_tailscale format
# Exit code: 0 if found, 1 if not found
get_address() {
    local alias="$1"
    local route_obj username hostroute tailscale_required
    
    route_obj=$(jq --arg alias "$alias" '.[$alias] // empty' "$ROUTES_JSON" 2>/dev/null)
    if [ "$route_obj" = "null" ] || [ -z "$route_obj" ]; then
        return 1
    fi
    
    username=$(echo "$route_obj" | jq -r '.username // empty')
    hostroute=$(echo "$route_obj" | jq -r '.hostroute // empty')
    tailscale_required=$(echo "$route_obj" | jq -r '.tailscale_required // "no"')
    
    if [ -z "$username" ] || [ -z "$hostroute" ]; then
        return 1
    fi
    
    echo "$username@$hostroute:$tailscale_required"
    return 0
}

# Function to find partial matches for route aliases
# Usage: find_partial_matches <partial_input>
# Returns: matching aliases, one per line
find_partial_matches() {
    local input="$1"
    local matches=()
    
    for key in "${keys[@]}"; do
        # Match anywhere in the alias (subword/substring match), not just prefix
        if [[ "$key" == *"$input"* ]]; then
            matches+=("$key")
        fi
    done
    
    printf '%s\n' "${matches[@]}"
}

# Function to get best match for input (exact or partial)
# Usage: get_best_match <input>
# Returns: exact match, single partial match, or empty if ambiguous/none
get_best_match() {
    local input="$1"
    
    # Try exact match first
    if get_address "$input" >/dev/null 2>&1; then
        echo "$input"
        return 0
    fi
    
    # Try partial matches - bash 3.2 compatible way
    local matches=()
    while IFS= read -r match; do
        if [ -n "$match" ]; then
            matches+=("$match")
        fi
    done < <(find_partial_matches "$input")
    
    if [ ${#matches[@]} -eq 1 ]; then
        echo "${matches[0]}"
        return 0
    elif [ ${#matches[@]} -gt 1 ]; then
        return 2  # Ambiguous
    else
        return 1  # No matches
    fi
}

# Function to get route field for a given alias
# Usage: get_route_field <alias> <field>
# Fields: username, hostroute, tailscale_required, hosttype, dockercontainer
get_route_field() {
    local alias="$1"
    local field="$2"
    local result
    
    case "$field" in
        tailscale_required|hosttype)
            # These fields have defaults if missing
            local default_value
            if [ "$field" = "tailscale_required" ]; then
                default_value="no"
            else
                default_value="unknown"
            fi
            result=$(jq -r --arg alias "$alias" --arg field "$field" --arg default "$default_value" '.[$alias][$field] // $default' "$ROUTES_JSON" 2>/dev/null)
            ;;
        *)
            result=$(jq -r --arg alias "$alias" --arg field "$field" '.[$alias][$field] // empty' "$ROUTES_JSON" 2>/dev/null)
            ;;
    esac
    
    if [ "$result" = "null" ] || [ -z "$result" ]; then
        return 1
    fi
    
    echo "$result"
    return 0
}

# Function to get docker container info for a route
# Returns: user@host:needs_tailscale:container format
# Exit code: 0 if docker route found, 1 if not docker or not found
get_docker_info() {
    local alias="$1"
    local hosttype username hostroute tailscale_required dockercontainer
    
    hosttype=$(get_route_field "$alias" "hosttype" 2>/dev/null)
    if [ "$hosttype" != "docker" ]; then
        return 1
    fi
    
    username=$(get_route_field "$alias" "username" 2>/dev/null)
    hostroute=$(get_route_field "$alias" "hostroute" 2>/dev/null)
    tailscale_required=$(get_route_field "$alias" "tailscale_required" 2>/dev/null)
    dockercontainer=$(get_route_field "$alias" "dockercontainer" 2>/dev/null)
    
    if [ -z "$username" ] || [ -z "$hostroute" ] || [ -z "$dockercontainer" ]; then
        return 1
    fi
    
    echo "$username@$hostroute:$tailscale_required:$dockercontainer"
    return 0
}

# Build keys array from JSON (all available route aliases)
# Using bash 3.2 compatible method instead of mapfile
keys=()
while IFS= read -r key; do
    keys+=("$key")
done < <(jq -r 'keys[]' "$ROUTES_JSON" 2>/dev/null)
