#!/bin/sh

# Bootstrap script for NixOS dotfiles
# Sets DOTFILES env var and runs initial rebuild

dir="$(cd "$(dirname "$0")" && pwd)"

# Set DOTFILES env var for zsh
env_line="export DOTFILES=\"$dir\""
if ! grep -q "^export DOTFILES=" ~/.zshenv 2>/dev/null; then
  echo "$env_line" >>~/.zshenv
else
  sed -i "s|^export DOTFILES=.*|$env_line|" ~/.zshenv
fi

# Source it for current session
export DOTFILES="$dir"

# Run initial rebuilds
echo "Running initial NixOS rebuild..."
sudo nixos-rebuild switch --flake "$dir/nix#$(hostname)"

echo "Running initial Home Manager rebuild..."
home-manager switch --flake "$dir/nix#jcing@$(hostname)"

echo "Done! You may need to restart your shell for DOTFILES to take effect."
