# Shared Hyprland desktop environment configuration
{ pkgs, username, ... }:

{
  # Desktop packages
  environment.systemPackages = with pkgs; [
    # Hyprland ecosystem
    wezterm
    rofi
    waybar
    dunst
    awww
    hyprshot
    hypridle
    hyprlock
    wlogout
    # Utilities
    networkmanagerapplet
    nwg-displays
    nwg-look
    wlsunset
    brightnessctl
    wl-clipboard
    pwvucontrol
    libnotify
  ];

  # Hyprland
  programs.hyprland.enable = true;

  # ydotool daemon — synthesizes real input events (mouse wheel, unicode typing)
  # Used by Hyprland keybinds for scroll injection.
  programs.ydotool.enable = true;
  users.users.${username}.extraGroups = [ "ydotool" ];

  # Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };

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

