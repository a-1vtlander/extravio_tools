#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/routing/common.sh"

echo "Running test_check_host_resolution..."

# localhost should be reachable
if check_host_resolution 127.0.0.1; then
    echo "  [OK] 127.0.0.1 reachable"
else
    echo "  [FAIL] 127.0.0.1 should be reachable"
    exit 1
fi

# Reserved TEST-NET-3 address should be unreachable in most environments
if check_host_resolution 203.0.113.1; then
    echo "  [WARN] 203.0.113.1 unexpectedly reachable (environment may differ)"
else
    echo "  [OK] 203.0.113.1 unreachable"
fi

echo "test_check_host_resolution: done"
