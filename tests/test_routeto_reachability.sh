#!/bin/bash
# Test routeto reachability check uses only hostname, not user@host
set -euo pipefail

MOCKBIN=$(mktemp -d)
PATH="$MOCKBIN:$PATH"

# Mock ping, host, ssh
cat > "$MOCKBIN/ping" <<'EOF'
#!/bin/bash
if [[ "$1" == "-c" ]]; then shift; fi
if [[ "$1" == "-W" ]]; then shift 2; fi
if [[ "$1" == "192.168.4.70" ]]; then exit 0; fi
exit 1
EOF
chmod +x "$MOCKBIN/ping"

cat > "$MOCKBIN/host" <<'EOF'
#!/bin/bash
if [[ "$1" == "192.168.4.70" ]]; then exit 0; fi
exit 1
EOF
chmod +x "$MOCKBIN/host"

cat > "$MOCKBIN/ssh" <<'EOF'
#!/bin/bash
echo "MOCK SSH: $@" >&2
exit 0
EOF
chmod +x "$MOCKBIN/ssh"

# Minimal mock get_routes.sh and common.sh
cat > get_routes.sh <<'EOF'
get_best_match() { echo ha-primary; return 0; }
get_docker_info() { return 1; }
get_address() { echo "vtlander-hassio@192.168.4.70:no"; return 0; }
EOF
cat > common.sh <<'EOF'
ensure_ssh_agent() { :; }
ensure_host_reachability_if_tailscale_required() { :; }
EOF

cp ../routing/routeto routeto_test
chmod +x routeto_test

output=$(./routeto_test ha-primary 2>&1)

if echo "$output" | grep -q 'MOCK SSH:'; then
  echo "PASS: Used only hostname for reachability check"
else
  echo "FAIL: Did not use only hostname for reachability"
  echo "$output"
  exit 1
fi

rm -rf "$MOCKBIN" routeto_test get_routes.sh common.sh