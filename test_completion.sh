#!/bin/bash

echo "=== Testing Bash Completion for Extravio Tools ==="

cd "$(dirname "$0")"

# Test if completion script can be sourced
if source routing/completion.bash 2>/dev/null; then
    echo "✅ Completion script loaded successfully"
else
    echo "❌ Failed to load completion script"
    exit 1
fi

# Test if completion function exists
if declare -F _extravio_completion >/dev/null; then
    echo "✅ Completion function _extravio_completion defined"
else
    echo "❌ Completion function not found"
    exit 1
fi

# Test if completion is registered
if complete -p routeto 2>/dev/null | grep -q "_extravio_completion"; then
    echo "✅ Completion registered for routeto"
else
    echo "❌ Completion not registered for routeto"
fi

echo
echo "To enable bash completion for your session:"
echo "  source $(pwd)/routing/completion.bash"
echo
echo "To enable bash completion permanently, add this line to your ~/.bashrc or ~/.zshrc:"
echo "  source \"$(pwd)/routing/completion.bash\""
echo
echo "Or run the installer which will do this automatically:"
echo "  ./install.sh"
echo

echo "Available routes for testing tab completion:"
if source routing/get_routes.sh 2>/dev/null; then
    for key in "${keys[@]}"; do
        echo "  $key"
    done
fi