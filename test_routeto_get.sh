#!/usr/bin/env bash
set -euo pipefail

echo "=== test_routeto_get.sh ==="

echo "Test: known alias with --get"
out=$(bash routing/routeto --get ha-primary 2>&1)
rc=$?
if [ $rc -ne 0 ]; then
  echo "FAIL: expected exit 0, got $rc"
  echo "$out"
  exit 1
fi
if [ "$out" != "192.168.4.70" ]; then
  echo "FAIL: unexpected output for ha-primary: '$out'"
  exit 1
fi
echo "OK"

echo "Test: unknown alias with --get"
if out=$(bash routing/routeto --get nosuch 2>&1); then
  rc=0
else
  rc=$?
fi
if [ $rc -eq 0 ]; then
  echo "FAIL: expected non-zero exit for unknown alias"
  exit 1
fi
if ! echo "$out" | grep -q "Available aliases"; then
  echo "FAIL: expected 'Available aliases' in output"
  echo "$out"
  exit 1
fi
echo "OK"

echo "Test: unknown alias without --get"
if out=$(bash routing/routeto nosuch 2>&1); then
  rc=0
else
  rc=$?
fi
if [ $rc -eq 0 ]; then
  echo "FAIL: expected non-zero exit for unknown alias"
  exit 1
fi
if ! echo "$out" | grep -q "Available aliases"; then
  echo "FAIL: expected 'Available aliases' in output"
  echo "$out"
  exit 1
fi
echo "OK"

echo "All tests passed."
exit 0
