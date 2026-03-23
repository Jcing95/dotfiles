# Home Manager configuration for homelab
{ pkgs, ... }:

{
  imports = [
    ./home-modules/git.nix
  ];

  home.stateVersion = "25.05";

  home.file.".config/wezterm".source = ../wezterm;
  home.file.".config/nvim".source = ../lazyvim;
  home.file.".config/waybar".source = ../waybar;
  home.file.".config/hypr/hyprland.conf".source = ../hypr/common.conf;
  home.file.".config/hypr/hyprlock.conf".source = ../hypr/hyprlock.conf;
  home.file.".config/hypr/hypridle.conf".source = ../hypr/hypridle.conf;
  home.file.".config/hypr/host.conf".source = ../hypr/homelab.conf;

  home.packages = with pkgs; [
    brave
    spotify
    claude-code
  ];

  home.pointerCursor = {
    name = "Nordzy-cursors";
    package = pkgs.nordzy-cursor-theme;
    size = 24;
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

  programs.home-manager.enable = true;
}
