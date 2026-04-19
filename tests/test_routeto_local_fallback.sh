#!/bin/bash
# Test routeto .local fallback logic with mocked ping, host, and ssh

set -euo pipefail

# Mocked commands directory
MOCKBIN=$(mktemp -d)
PATH="$MOCKBIN:$PATH"

# Create mock ping, host, and ssh
cat > "$MOCKBIN/ping" <<'EOF'
#!/bin/bash
# Simulate ping: fail for foo.local, succeed for foo
if [[ "$1" == "-c" ]]; then shift; fi
if [[ "$1" == "-W" ]]; then shift 2; fi
if [[ "$1" == "foo.local" ]]; then exit 1; fi
if [[ "$1" == "foo" ]]; then exit 0; fi
exit 1
EOF
chmod +x "$MOCKBIN/ping"

cat > "$MOCKBIN/host" <<'EOF'
#!/bin/bash
# Simulate host: fail for foo.local, succeed for foo
if [[ "$1" == "foo.local" ]]; then exit 1; fi
if [[ "$1" == "foo" ]]; then exit 0; fi
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
get_best_match() { echo foo.local; return 0; }
get_docker_info() { return 1; }
get_address() { echo "user@foo.local:no"; return 0; }
EOF
cat > common.sh <<'EOF'
ensure_ssh_agent() { :; }
ensure_host_reachability_if_tailscale_required() { :; }
EOF

# Create a minimal routeto copy for testing
cp ../routing/routeto routeto_test
chmod +x routeto_test

# Run the test
output=$(./routeto_test foo.local 2>&1)

# Check output for fallback
if echo "$output" | grep -q 'trying fallback: foo'; then
  echo "PASS: Fallback to non-.local triggered as expected"
else
  echo "FAIL: Fallback to non-.local not triggered"
  echo "$output"
  exit 1
fi

# Cleanup
rm -rf "$MOCKBIN" routeto_test get_routes.sh common.sh
