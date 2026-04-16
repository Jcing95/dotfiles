{ config, pkgs, lib, ... }:

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
    ../../modules/adguardhome.nix
    ../../modules/k3s.nix
    ../../modules/k3s-media.nix
  ];

  networking.hostName = "homelab";

  # Use local Adguard Home for DNS (overrides core.nix Cloudflare defaults)
  # Adguard Home rewrites *.jcing.de → 192.168.0.121, no /etc/hosts needed
  networking.nameservers = lib.mkForce [ "127.0.0.1" ];
  networking.networkmanager.insertNameservers = lib.mkForce [ "127.0.0.1" ];

  # Enable Wake on LAN on Ethernet
  networking.interfaces.enp3s0f1.wakeOnLan.enable = true;

  # Allow laptop to stay on with lid closed (connected to external display)
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchDocked = "ignore";
    HandleLidSwitchExternalPower = "ignore";
  };

}
