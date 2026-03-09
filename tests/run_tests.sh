#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR/.."

echo "Running tests..."
bash tests/test_common.sh
echo "Tests completed."
