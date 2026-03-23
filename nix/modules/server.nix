# Homelab-specific server configuration
{ pkgs, lib, ... }:

{
  imports = [ ./hyprland.nix ];

  # Additional server packages
  environment.systemPackages = with pkgs; [
    cloudflared
    wireguard-tools
  ];

  # Display manager with simple greetd
  services.greetd.settings = {
    default_session = {
      command = "start-hyprland";
      user = "jcing";
    };
  };

  # Boot into headless mode by default
  # Use `tv-on` alias to start greetd/Hyprland when needed
  systemd.defaultUnit = lib.mkForce "multi-user.target";
}
