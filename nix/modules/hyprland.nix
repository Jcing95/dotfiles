# Shared Hyprland desktop environment configuration
{ pkgs, username, ... }:

{
  # Desktop packages
  environment.systemPackages = with pkgs; [
    # Hyprland ecosystem
    wezterm
    dmenu
    rofi
    waybar
    dunst
    awww
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
  ];

  # Fonts
  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
  ];

  # Hyprland
  programs.hyprland.enable = true;

  # ydotool daemon — synthesizes real input events (mouse wheel, unicode typing)
  # Used by Hyprland keybinds for scroll injection.
  programs.ydotool.enable = true;
  users.users.${username}.extraGroups = [ "ydotool" ];

  # Steam
  programs.steam.enable = true;

  # Display manager
  services.greetd.enable = true;

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.General.JustWorksRepairing = "always";
  };
  services.blueman.enable = true;
}

