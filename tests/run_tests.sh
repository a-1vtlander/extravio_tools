#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR/.."

echo "Running tests..."
bash tests/test_common.sh
bash tests/test_user_routes_merge.sh
echo "Tests completed."
