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
    # Gaming overlay (frametime/FPS); gamescope + gamemode are below.
    mangohud
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

  # Gaming helpers (shared across all desktop hosts):
  # - gamescope: micro-compositor that gives games proper frame pacing — the
  #   main fix for stutter on fixed-refresh displays with no VRR (e.g. lab's
  #   60 Hz HDMI TV). Use via Steam launch options: `gamescope -f -- %command%`.
  # - gamemode: switches the CPU governor to performance while a game runs.
  # - mangohud: on-screen frametime/FPS overlay to actually measure stutter.
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };
  programs.gamemode.enable = true;

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

