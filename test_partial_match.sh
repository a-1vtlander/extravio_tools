#!/bin/bash

echo "Testing partial matching functions..."
cd "$(dirname "$0")/routing"

# Source the routes
source ./get_routes.sh

echo "Available routes: ${keys[*]}"
echo

# Test exact match
echo "Testing exact match (ha-primary):"
result=$(get_best_match "ha-primary")
echo "Result: $result (exit code: $?)"
echo

# Test unique partial match
echo "Testing unique partial match (ha-p):"
result=$(get_best_match "ha-p") 
exit_code=$?
echo "Result: $result (exit code: $exit_code)"
echo

# Test ambiguous partial match 
echo "Testing ambiguous partial match (ha):"
result=$(get_best_match "ha")
exit_code=$?
echo "Result: $result (exit code: $exit_code)"
if [ $exit_code -eq 2 ]; then
    echo "Multiple matches found:"
    find_partial_matches "ha" | sed 's/^/  /'
fi
echo

echo "Testing routeto with partial match..."
./routing/routeto ha-p 2>&1 | head -3