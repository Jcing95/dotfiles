#!/bin/sh

# Bootstrap script for NixOS / nix-darwin dotfiles
# Detects OS, installs Nix/Lix if needed, and runs initial rebuild

set -e

dir="$(cd "$(dirname "$0")" && pwd)"
os="$(uname -s)"

# Set DOTFILES env var for zsh
echo "Setting up DOTFILES environment variable..."
env_line="export DOTFILES=\"$dir\""
if ! grep -q "^export DOTFILES=" ~/.zshenv 2>/dev/null; then
  echo "$env_line" >>~/.zshenv
else
  if [ "$os" = "Darwin" ]; then
    sed -i '' "s|^export DOTFILES=.*|$env_line|" ~/.zshenv
  else
    sed -i "s|^export DOTFILES=.*|$env_line|" ~/.zshenv
  fi
fi

# Source it for current session
export DOTFILES="$dir"

if [ "$os" = "Darwin" ]; then
  # macOS: Install Lix if nix is not present
  if ! command -v nix >/dev/null 2>&1; then
    echo "Installing Lix..."
    curl -sSf -L https://install.lix.systems/lix | sh -s -- install
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi

  echo "Bootstrapping nix-darwin..."
  nix run nix-darwin -- switch --flake "$dir/nix#macbook-jcing"

  echo "Running initial Home Manager rebuild..."
  nix run home-manager -- switch --flake "$dir/nix#jcing@macbook-jcing"

else
  # Linux (NixOS): Nix is already installed
  echo "Running initial NixOS rebuild..."
  sudo nixos-rebuild switch --flake "$dir/nix#$(hostname)"

  echo "Running initial Home Manager rebuild..."
  home-manager switch --flake "$dir/nix#jcing@$(hostname)"
fi

echo "Done! Please restart your shell for all changes to take effect."
