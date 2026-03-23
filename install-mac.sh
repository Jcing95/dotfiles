#!/bin/sh

# Bootstrap script for nix-darwin dotfiles
# Installs Lix, bootstraps nix-darwin, and runs initial rebuild

set -e

dir="$(cd "$(dirname "$0")" && pwd)"

# Set DOTFILES env var for zsh
echo "Setting up DOTFILES environment variable..."
env_line="export DOTFILES=\"$dir\""
if ! grep -q "^export DOTFILES=" ~/.zshenv 2>/dev/null; then
  echo "$env_line" >>~/.zshenv
else
  sed -i '' "s|^export DOTFILES=.*|$env_line|" ~/.zshenv
fi

# Source it for current session
export DOTFILES="$dir"

# Install Lix if nix is not present
if ! command -v nix >/dev/null 2>&1; then
  echo "Installing Lix..."
  curl -sSf -L https://install.lix.systems/lix | sh -s -- install

  # Source nix for current session
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# Bootstrap nix-darwin (first time, darwin-rebuild doesn't exist yet)
echo "Bootstrapping nix-darwin..."
nix run nix-darwin -- switch --flake "$dir/nix#macbook-jcing"

echo "Running initial Home Manager rebuild..."
nix run home-manager -- switch --flake "$dir/nix#jcing@macbook-jcing"

echo "Done! Please restart your shell for all changes to take effect."
