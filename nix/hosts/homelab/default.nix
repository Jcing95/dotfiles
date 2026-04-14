{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/core.nix
    ../../modules/server.nix
    ../../modules/audio.nix
    ../../modules/nvidia.nix
    ../../modules/sshd.nix
    ../../modules/cloudflared.nix
    ../../modules/sops.nix
    ../../modules/k3s.nix
    ../../modules/k3s-media.nix
  ];

  networking.hostName = "homelab";

  networking.hosts."127.0.0.1" = [
    "jellyfin.homelab.local"      "sonarr.homelab.local"
    "radarr.homelab.local"        "prowlarr.homelab.local"
    "bazarr.homelab.local"        "jellyseerr.homelab.local"
    "download-client.homelab.local"
    "flaresolverr.homelab.local"  "homepage.homelab.local"
  ];

  # Allow laptop to stay on with lid closed (connected to external display)
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchDocked = "ignore";
    HandleLidSwitchExternalPower = "ignore";
  };

}
