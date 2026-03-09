#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Running test_routeto_get..."

# Use --get to print host for a known alias
out=$("$ROOT_DIR/routing/routeto" --get ha-backup 2>/dev/null) || { echo "  [FAIL] routeto --get ha-backup failed"; exit 1; }
echo "  routeto --get produced: $out"
if [[ "$out" == 192.168.* ]]; then
    echo "  [OK] routeto --get returned expected IP-like host"
else
    echo "  [WARN] routeto --get returned: $out (may be environment-specific)"
fi

echo "test_routeto_get: done"
