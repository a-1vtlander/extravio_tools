#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

echo "Running tests..."
failures=0

for t in tests/*.sh; do
    echo
    echo "=== $t ==="
    if bash "$t"; then
        echo "=> PASS: $t"
    else
        echo "=> FAIL: $t"
        failures=$((failures+1))
    fi
done

echo
if [ $failures -eq 0 ]; then
    echo "All tests passed"
    exit 0
else
    echo "$failures test(s) failed"
    exit 1
fi
