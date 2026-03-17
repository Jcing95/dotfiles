# Home Manager configuration for homelab
{ pkgs, ... }:

{
  imports = [
  ];

  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    brave
    telegram-desktop
    discord
    spotify
    prismlauncher
    nextcloud-client
    claude-code
    bolt-launcher
    runelite
    devenv
    hueadm
    heroic
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

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style.name = "adwaita-dark";
  };

  programs.home-manager.enable = true;
}
