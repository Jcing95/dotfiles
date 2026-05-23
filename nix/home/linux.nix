# Shared Home Manager configuration for Linux desktops
{ config, pkgs, ... }:

let
  dotfiles = "${config.home.homeDirectory}/dotfiles";
in
{
  imports = [
    ./common.nix
  ];
 
  home.packages = with pkgs; [
    mgba
  ];
  home.stateVersion = "25.05";

  programs.zsh.shellAliases = {
    rebuild = "sudo nixos-rebuild switch --flake $DOTFILES/nix#$(hostname)";
    os-gc = "sudo nix-env --delete-generations old && nix-collect-garbage -d";
    config = "nvim $DOTFILES";
    secrets = "sudo -E sops";
    k = "kubectl";
  };

  # Dotfile symlinks (out-of-store so changes are reflected immediately)
  home.file.".config/wezterm".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/wezterm";
  home.file.".config/nvim".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/lazyvim";
  home.file.".config/waybar".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/waybar";
  home.file.".config/hypr/hyprland.lua".source   = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/hypr/hyprland.lua";
  home.file.".config/hypr/appearance.lua".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/hypr/appearance.lua";
  home.file.".config/hypr/input.lua".source      = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/hypr/input.lua";
  home.file.".config/hypr/devices.lua".source    = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/hypr/devices.lua";
  home.file.".config/hypr/binds.lua".source      = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/hypr/binds.lua";
  home.file.".config/hypr/rules.lua".source      = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/hypr/rules.lua";
  home.file.".config/hypr/autostart.lua".source  = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/hypr/autostart.lua";
  home.file.".config/hypr/hyprlock.conf".source  = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/hypr/hyprlock.conf";
  home.file.".config/hypr/hypridle.conf".source  = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/hypr/hypridle.conf";
  home.file.".config/dunst".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/dunst";

  home.pointerCursor = {
    name = "Nordzy-cursors";
    package = pkgs.nordzy-cursor-theme;
    gtk.enable = true;
    x11.enable = true;
  };

  gtk = {
    enable = true;

    theme = {
      name = "Ayu-Dark";
      package = pkgs.ayu-theme-gtk;
    };

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };

    gtk4 = {
      theme = null;  # GTK4 apps use libadwaita, explicit theming not needed
      extraConfig.gtk-application-prefer-dark-theme = true;
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style.name = "adwaita-dark";
  };
}
