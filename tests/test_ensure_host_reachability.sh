#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/routing/common.sh"

echo "Running test_ensure_host_reachability_if_tailscale_required..."

# When host is reachable, function should return 0 and not attempt to start tailscale
if ensure_host_reachability_if_tailscale_required yes 127.0.0.1; then
    echo "  [OK] reachable host skipped tailscale activation"
else
    echo "  [FAIL] reachable host should not trigger tailscale up"
    exit 1
fi

# Missing host should trigger ASSERT (exit code 2)
( source "$ROOT_DIR/routing/common.sh"; ensure_host_reachability_if_tailscale_required yes "" )
rc=$?
if [ $rc -eq 2 ]; then
    echo "  [OK] missing host triggers ASSERT (rc=2)"
else
    echo "  [FAIL] missing host should trigger ASSERT (rc=2), got rc=$rc"
    exit 1
fi

echo "test_ensure_host_reachability_if_tailscale_required: done"
