#! /bin/sh

dir=${PWD}
mkdir -p ~/.config
mkdir -p ~/.config/Nextcloud
mkdir -p ~/.config/hypr/
ln -sf $dir/configuration.nix /etc/nixos/configuration.nix
ln -sf $dir/wezterm/ ~/.config/wezterm
ln -sf $dir/lazyvim ~/.config/nvim
ln -sf $dir/nextcloud.cfg ~/.config/Nextcloud
ln -sf $dir/hyprland.conf ~/.config/hypr/hyprland.conf
