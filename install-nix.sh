#! /bin/sh

dir="$(cd "$(dirname "$0")" && pwd)"

# Determine hostname for monitor config
hostname=$(hostname)

mkdir -p ~/.config
mkdir -p ~/.config/Nextcloud
mkdir -p ~/.config/hypr/
ln -sfn $dir/wezterm ~/.config/wezterm
ln -sfn $dir/waybar ~/.config/waybar
ln -sfn $dir/lazyvim ~/.config/nvim
ln -sfn $dir/nextcloud.cfg ~/.config/Nextcloud
ln -sfn $dir/hyprland/common.conf ~/.config/hypr/hyprland.conf
ln -sfn $dir/hyprland/hyprlock.conf ~/.config/hypr/hyprlock.conf
ln -sfn $dir/hyprland/$hostname.conf ~/.config/hypr/host.conf

# Set DOTFILES env var for zsh
env_line="export DOTFILES=\"$dir\""
if ! grep -q "^export DOTFILES=" ~/.zshenv 2>/dev/null; then
  echo "$env_line" >>~/.zshenv
else
  sed -i "s|^export DOTFILES=.*|$env_line|" ~/.zshenv
fi
