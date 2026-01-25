# Home Manager configuration entry point
{ pkgs, ... }:

{
  imports = [
  ];

  # For unstable, use a recent stable version
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    home-manager
    brave
    telegram-desktop
    discord
    spotify
    prismlauncher
    nextcloud-client
    claude-code
    runelite
    devenv
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
    
    # Ayu Dark GTK theme
    theme = {
      name = "Ayu-Dark";
      package = pkgs.ayu-theme-gtk;
    };

    # Icon theme - pick one you like:
    # - papir:withus-icon-theme (Papirus-Dark) - clean, huge coverage
    # - tela-circle-icon-theme - modern, colorful circles
    # - tela-icon-theme - modern, colorful squares
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

#    font = {
#      name = "FiraCode Nerd Font";
#      size = 11;
#    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };

  # Qt apps should follow GTK theme
  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style.name = "adwaita-dark";
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;
}
