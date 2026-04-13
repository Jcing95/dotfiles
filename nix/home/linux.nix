# Shared Home Manager configuration for Linux desktops
{ pkgs, ... }:

{
  imports = [
    ./common.nix
  ];

  home.stateVersion = "25.05";

  programs.zsh.shellAliases = {
    rebuild = "sudo nixos-rebuild switch --flake $DOTFILES/nix#$(hostname)";
    os-gc = "sudo nix-env --delete-generations old && nix-collect-garbage -d";
    config = "nvim $DOTFILES";
  };

  home.file.".config/wezterm".source = ../../wezterm;
  home.file.".config/nvim".source = ../../lazyvim;
  home.file.".config/waybar".source = ../../waybar;
  home.file.".config/hypr/hyprland.conf".source = ../../hypr/common.conf;
  home.file.".config/hypr/hyprlock.conf".source = ../../hypr/hyprlock.conf;
  home.file.".config/hypr/hypridle.conf".source = ../../hypr/hypridle.conf;

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
