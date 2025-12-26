# Desktop environment configuration
{ config, pkgs, ... }:

{
  # Desktop packages
  environment.systemPackages = with pkgs; [
    # Desktop apps
    brave
    telegram-desktop
    discord
    spotify
    prismlauncher
    nextcloud-client
    
    # Hyprland ecosystem
    wezterm
    dmenu
    rofi
    waybar
    dunst
    hyprpaper
    hyprshot
    hypridle
    # Utilities
    networkmanagerapplet
    nwg-displays
    nwg-look
    wlsunset
    wl-clipboard   
    pwvucontrol
    gnome-keyring
    polkit
  ];

  # Fonts
  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
  ];

  # Hyprland
  programs.hyprland.enable = true;

  # Steam
  programs.steam.enable = true;

  # Display manager
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = false;

  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
}
