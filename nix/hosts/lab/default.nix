{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/core.nix
    ../../modules/fonts.nix
    ../../modules/neovim.nix
    ../../modules/server.nix
    ../../modules/audio.nix
    ../../modules/nvidia-lab.nix
    ../../modules/sshd.nix
    ../../modules/cloudflared.nix
    ../../modules/sops.nix
    ../../modules/adguardhome.nix
    ../../modules/k3s.nix
    ../../modules/k3s-storage.nix
    ../../modules/storage.nix
  ];

  networking.hostName = "lab";

  # Use local Adguard Home for DNS (overrides core.nix Cloudflare defaults)
  # Adguard Home rewrites *.jcing.de → 192.168.0.121, no /etc/hosts needed
  networking.nameservers = lib.mkForce [ "127.0.0.1" ];
  networking.networkmanager.insertNameservers = lib.mkForce [ "127.0.0.1" ];

  # Enable Wake on LAN on Ethernet
  networking.interfaces.enp3s0.wakeOnLan.enable = true;

}
