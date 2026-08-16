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
  programs.hyprland = {
    enable = true;
    # uwsm wraps the compositor in wayland-wm@hyprland.desktop.service and binds
    # it to graphical-session.target. Launched bare from greetd, Hyprland never
    # activates that target (it dropped hyprland-session.target), so every unit
    # gated on it stayed dead — including xdg-desktop-portal, which carries
    # `Requisite=graphical-session.target` and therefore failed instantly. No
    # portal meant no screen-share picker in Discord, and no wlsunset/hypridle.
    # Requires the uwsm session entry in greetd and `uwsm finalize` from
    # hypr/config/uwsm.lua.
    withUWSM = true;
  };

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
    # Must stay false: capSysNice installs gamescope as a file-capability binary
    # (cap_sys_nice=eip), which makes the loader run it AT_SECURE and strip
    # LD_PRELOAD/LD_LIBRARY_PATH. Steam's pressure-vessel runtime needs both, so
    # any game launched via `gamescope -- %command%` exits instantly.
    capSysNice = false;
    # VK_LAYER_FROG_gamescope_wsi — without it a game running inside gamescope
    # never sees an HDR10 swapchain format, so its in-game HDR toggle stays
    # greyed out even with `gamescope --hdr-enabled`.
    enableWsi = true;
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

