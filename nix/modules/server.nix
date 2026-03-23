# Desktop environment configuration
{ config, pkgs, lib, ... }:

{
  # Desktop packages
  environment.systemPackages = with pkgs; [
    # Hyprland ecosystem
    wezterm
    dmenu
    rofi
    waybar
    dunst
    hyprpaper
    hyprshot
    hypridle
    hyprlock

    # Utilities
    networkmanagerapplet
    nwg-displays
    nwg-look
    wlsunset
    brightnessctl
    wl-clipboard
    pwvucontrol
    gnome-keyring
    polkit
    libnotify


    #Networking
    cloudflared
    wireguard-tools
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
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "start-hyprland";
        user = "jcing";
      };
    };
  };

  # Boot into headless mode by default
  # Use `tv-on` alias to start greetd/Hyprland when needed
  systemd.defaultUnit = lib.mkForce "multi-user.target";
  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

}
