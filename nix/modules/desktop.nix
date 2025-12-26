# Desktop environment configuration
{ config, pkgs, ... }:

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
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd Hyprland";
        user = "greeter";
      };
    };
  };
  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
}
