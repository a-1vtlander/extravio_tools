#!/bin/bash

# Install script to add all subdirectories under the project root to the user's PATH

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SHELL_RC="$HOME/.bashrc"
if [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_RC="$HOME/.zshrc"
fi

echo "Adding directories to PATH in $SHELL_RC..."

# Add the project root to PATH
if ! grep -q "export PATH=\"$PROJECT_ROOT:\$PATH\"" "$SHELL_RC"; then
    echo "export PATH=\"$PROJECT_ROOT:\$PATH\"" >> "$SHELL_RC"
    echo "Added $PROJECT_ROOT to PATH"
else
    echo "$PROJECT_ROOT already in PATH"
fi

# Find all non-hidden subdirectories under project root
for dir in $(find "$PROJECT_ROOT" -mindepth 1 -maxdepth 1 -type d -name "[^.]*"); do
    # Check if already in PATH or rc file
    if ! grep -q "export PATH=\"$dir:\$PATH\"" "$SHELL_RC"; then
        echo "export PATH=\"$dir:\$PATH\"" >> "$SHELL_RC"
        echo "Added $dir to PATH"
    else
        echo "$dir already in PATH"
    fi
done

echo "Installation complete. Please restart your shell or run 'source $SHELL_RC' to apply changes."