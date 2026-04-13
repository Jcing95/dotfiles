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
  ];

  networking.hostName = "homelab";

  # Allow laptop to stay on with lid closed (connected to external display)
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchDocked = "ignore";
    HandleLidSwitchExternalPower = "ignore";
  };

}
