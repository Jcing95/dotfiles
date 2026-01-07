#! /bin/sh

dir="$(cd "$(dirname "$0")" && pwd)"
mkdir -p ~/.config
mkdir -p ~/.config/Nextcloud
mkdir -p ~/.config/aerospace

ln -sfn $dir/wezterm ~/.config/wezterm
ln -sfn $dir/lazyvim ~/.config/nvim
ln -sfn $dir/nextcloud.cfg ~/.config/Nextcloud
ln -sfn $dir/aerospace.toml ~/.config/aerospace/aerospace.toml
