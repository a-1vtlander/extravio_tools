#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

source routing/get_routes.sh
source routing/common.sh

echo "Running test: check_host_resolution (127.0.0.1 should succeed)"
if check_host_resolution 127.0.0.1; then
    echo "PASS: ping localhost"
else
    echo "FAIL: ping localhost"
    exit 1
fi

echo "Running test: check_host_resolution (empty should fail)"
if check_host_resolution ""; then
    echo "FAIL: empty host should not resolve"
    exit 1
else
    echo "PASS: empty host failed as expected"
fi

echo "Running test: get_address for existing alias (park-st-mac)"
addr=$(get_address park-st-mac)
if [[ "$addr" == *"@"* && "$addr" == *":"* ]]; then
    echo "PASS: get_address -> $addr"
else
    echo "FAIL: get_address returned unexpected: $addr"
    exit 1
fi

echo "Running test: routeto --get outputs host only"
out=$(./routing/routeto --get park-st-mac)
host_expected=$(echo "$addr" | cut -d: -f1 | sed 's/^.*@//')
if [ "$out" = "$host_expected" ]; then
    echo "PASS: routeto --get -> $out"
else
    echo "FAIL: routeto --get returned '$out' expected '$host_expected'"
    exit 1
fi

echo "Running test: ensure_host_reachability_if_tailscale_required stubs"
# prepare fake tailscale to capture calls
tmpbin=$(mktemp -d)
cat > "$tmpbin/tailscale" <<'TS'
#!/usr/bin/env bash
if [ "$1" = "up" ]; then
  touch "$TMPDIR/tailscale_up_called" 2>/dev/null || touch "$TMPDIR/tailscale_up_called"
  exit 0
fi
if [ "$1" = "status" ]; then
  echo '{"BackendState":"Unknown"}'
  exit 0
fi
exit 0
TS
chmod +x "$tmpbin/tailscale"
export TMPDIR="$ROOT_DIR/tests/tmp"
mkdir -p "$TMPDIR"
export PATH="$tmpbin:$PATH"

echo "- When host reachable, tailscale should NOT be called"
check_host_resolution() { return 0; }
rm -f "$TMPDIR/tailscale_up_called" || true
ensure_host_reachability_if_tailscale_required yes 127.0.0.1
if [ -f "$TMPDIR/tailscale_up_called" ]; then
  echo "FAIL: tailscale up was called unexpectedly"
  exit 1
else
  echo "PASS: tailscale not called when host reachable"
fi

echo "- When host NOT reachable, tailscale SHOULD be called"
check_host_resolution() { return 1; }
rm -f "$TMPDIR/tailscale_up_called" || true
ensure_host_reachability_if_tailscale_required yes unreachable-host.local
if [ -f "$TMPDIR/tailscale_up_called" ]; then
  echo "PASS: tailscale up called as expected"
else
  echo "FAIL: tailscale up was not called"
  exit 1
fi

echo "All tests passed."
