#! /bin/sh

dir="$(cd "$(dirname "$0")" && pwd)"
mkdir -p ~/.config
mkdir -p ~/.config/Nextcloud
mkdir -p ~/.config/hypr/
ln -sfn $dir/wezterm ~/.config/wezterm
ln -sfn $dir/waybar ~/.config/waybar
ln -sfn $dir/lazyvim ~/.config/nvim
ln -sfn $dir/nextcloud.cfg ~/.config/Nextcloud
ln -sfn $dir/hyprland.conf ~/.config/hypr/hyprland.conf
ln -sfn $dir/hyprlock.conf ~/.config/hypr/hyprlock.conf

# Set DOTFILES env var for zsh
env_line="export DOTFILES=\"$dir\""
if ! grep -q "^export DOTFILES=" ~/.zshenv 2>/dev/null; then
  echo "$env_line" >>~/.zshenv
  echo "Added DOTFILES to ~/.zshenv"
else
  sed -i "s|^export DOTFILES=.*|$env_line|" ~/.zshenv
  echo "Updated DOTFILES in ~/.zshenv"
fi
