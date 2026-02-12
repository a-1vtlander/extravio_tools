#!/usr/bin/env bash
set -euo pipefail

echo "SSH Key Generation Tool"
echo "======================="

# Defaults (modern)
DEFAULT_KEY_TYPE="ed25519"
DEFAULT_KEY_FILE="$HOME/.ssh/id_ed25519"
DEFAULT_RSA_BITS="4096"

KEY_TYPE="$DEFAULT_KEY_TYPE"
KEY_FILE="$DEFAULT_KEY_FILE"
RSA_BITS="$DEFAULT_RSA_BITS"
COMMENT=""
PASSPHRASE=""

# Ensure ~/.ssh exists with correct perms
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# Prompt: key type
read -r -p "Enter key type (ed25519, rsa, ecdsa) [$DEFAULT_KEY_TYPE]: " input
if [[ -n "${input:-}" ]]; then
  KEY_TYPE="$input"
fi

# Validate key type
case "$KEY_TYPE" in
  ed25519|rsa|ecdsa) ;;
  *)
    echo "Error: unsupported key type '$KEY_TYPE' (use ed25519, rsa, ecdsa)" >&2
    exit 1
    ;;
esac

# Prompt: key file (default depends on type)
if [[ "$KEY_TYPE" == "rsa" ]]; then
  DEFAULT_KEY_FILE="$HOME/.ssh/id_rsa"
elif [[ "$KEY_TYPE" == "ecdsa" ]]; then
  DEFAULT_KEY_FILE="$HOME/.ssh/id_ecdsa"
else
  DEFAULT_KEY_FILE="$HOME/.ssh/id_ed25519"
fi

read -r -p "Enter key file path [$DEFAULT_KEY_FILE]: " input
if [[ -n "${input:-}" ]]; then
  KEY_FILE="$input"
else
  KEY_FILE="$DEFAULT_KEY_FILE"
fi

# Prevent overwrite unless user confirms
if [[ -e "$KEY_FILE" || -e "$KEY_FILE.pub" ]]; then
  read -r -p "Key file exists. Overwrite? (yes/no) [no]: " yn
  yn=${yn:-no}
  if [[ "$yn" != "yes" ]]; then
    echo "Aborted (won't overwrite existing key)."
    exit 1
  fi
fi

# Prompt: comment
read -r -p "Enter key comment (e.g., email/label) [none]: " COMMENT

# Prompt: passphrase + confirm
read -r -s -p "Enter passphrase (leave blank for no passphrase): " PASSPHRASE
echo
read -r -s -p "Confirm passphrase: " PASSPHRASE2
echo
if [[ "$PASSPHRASE" != "$PASSPHRASE2" ]]; then
  echo "Error: passphrases do not match." >&2
  exit 1
fi

# Build ssh-keygen args safely
args=(-t "$KEY_TYPE" -f "$KEY_FILE" -N "$PASSPHRASE")
if [[ -n "$COMMENT" ]]; then
  args+=(-C "$COMMENT")
fi

# Only pass -b for rsa/ecdsa (ed25519 ignores/doesn't need it)
if [[ "$KEY_TYPE" == "rsa" ]]; then
  args+=(-b "$RSA_BITS")
elif [[ "$KEY_TYPE" == "ecdsa" ]]; then
  # Common ECDSA sizes: 256, 384, 521. Default to 256 if you want to set it.
  # Uncomment next line to force a size:
  # args+=(-b 256)
  :
fi

echo "Generating SSH key..."
ssh-keygen "${args[@]}"

echo "SSH key generated successfully!"
echo "Private key: $KEY_FILE"
echo "Public key:  $KEY_FILE.pub"
echo ""
echo "To add to SSH agent: ssh-add \"$KEY_FILE\""
if command -v pbcopy >/dev/null 2>&1; then
  echo "To copy public key to clipboard (macOS): pbcopy < \"$KEY_FILE.pub\""
elif command -v xclip >/dev/null 2>&1; then
  echo "To copy public key to clipboard (Linux): xclip -selection clipboard < \"$KEY_FILE.pub\""
elif command -v wl-copy >/dev/null 2>&1; then
  echo "To copy public key to clipboard (Wayland): wl-copy < \"$KEY_FILE.pub\""
else
  echo "To view public key: cat \"$KEY_FILE.pub\""
fi