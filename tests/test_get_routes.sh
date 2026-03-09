#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/routing/get_routes.sh"

echo "Running test_get_routes..."

out=$(get_address ha-backup 2>/dev/null) || { echo "  [FAIL] get_address ha-backup failed"; exit 1; }
echo "  got: $out"
# Expect format user@host:flag
if [[ "$out" == *@*:* ]]; then
    echo "  [OK] get_address format looks good"
else
    echo "  [FAIL] get_address output format unexpected"
    exit 1
fi

echo "test_get_routes: done"
