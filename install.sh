#!/bin/bash

# Install script to add all subdirectories under the project root to the user's PATH

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SHELL_RC="$HOME/.bashrc"
if [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_RC="$HOME/.zshrc"
fi

echo "Adding subdirectories to PATH in $SHELL_RC..."

# Find all subdirectories under project root
for dir in $(find "$PROJECT_ROOT" -type d -mindepth 1 -maxdepth 1); do
    # Check if already in PATH or rc file
    if ! grep -q "export PATH=\"$dir:\$PATH\"" "$SHELL_RC"; then
        echo "export PATH=\"$dir:\$PATH\"" >> "$SHELL_RC"
        echo "Added $dir to PATH"
    else
        echo "$dir already in PATH"
    fi
done

echo "Installation complete. Please restart your shell or run 'source $SHELL_RC' to apply changes."