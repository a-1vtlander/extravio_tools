#!/usr/bin/env bash
set -euo pipefail

echo "=== test_partial_match_extra.sh ==="

cd routing
source ./get_routes.sh

echo "Available routes: ${keys[*]}"

echo "Test: substring partial match 'primary' should match 'ha-primary'"
result=$(get_best_match "primary")
rc=$?
if [ $rc -ne 0 ]; then
  echo "FAIL: get_best_match returned non-zero for 'primary'"
  exit 1
fi
if [ "$result" != "ha-primary" ]; then
  echo "FAIL: expected 'ha-primary', got '$result'"
  exit 1
fi
echo "OK"

echo "All substring partial-match tests passed."

exit 0
