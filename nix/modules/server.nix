# Homelab-specific server configuration
{ pkgs, lib, username, ... }:

{
  imports = [ ./hyprland.nix ];

  # Additional server packages
  environment.systemPackages = with pkgs; [
    cloudflared
    wireguard-tools
  ];

  # Display manager with simple greetd. lab has no session picker (it autologins
  # straight into the compositor), so the uwsm wrapper that the other hosts get
  # from the hyprland-uwsm.desktop session entry has to be spelled out here.
  # This is the same command that entry runs — without it graphical-session.target
  # never activates and the shared `uwsm finalize` in hypr/config/uwsm.lua fails.
  services.greetd.settings = {
    default_session = {
      command = "uwsm start -e -D Hyprland hyprland.desktop";
      user = username;
    };
  };

  # Boot into headless mode by default
  # Use `tv-on` alias to start greetd/Hyprland when needed
  systemd.defaultUnit = lib.mkForce "multi-user.target";

  # Keep the Corne Choc Pro (homelab ZMK profile) connected while a graphical
  # session is up. lab is headless by default; blueman / the in-session BT agent
  # only run under Hyprland, so without this nothing re-grabs the keyboard on tv-on.
  systemd.services.corne-connect = {
    description = "Reconnect the Corne keyboard during graphical sessions";
    after    = [ "bluetooth.service" "greetd.service" ];
    partOf   = [ "greetd.service" ];   # stop on tv-off
    wantedBy = [ "greetd.service" ];   # start on tv-on
    serviceConfig = {
      Type = "simple";
      Restart = "on-failure";
      RestartSec = 5;
    };
    script = ''
      mac="F7:4D:AE:40:95:D2"   # Corne Choc Pro
      ${pkgs.bluez}/bin/bluetoothctl trust "$mac" || true
      while true; do
        ${pkgs.bluez}/bin/bluetoothctl connect "$mac" || true
        sleep 10
      done
    '';
  };
}
