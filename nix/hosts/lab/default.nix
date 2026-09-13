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
    ../../modules/tailscale.nix
    ../../modules/sops.nix
    ../../modules/adguardhome.nix
    ../../modules/k3s.nix
    ../../modules/k3s-storage.nix
    ../../modules/storage.nix
    ../../modules/games.nix
  ];

  networking.hostName = "lab";

  networking.nameservers = lib.mkForce [ "127.0.0.1" ];
  networking.networkmanager.insertNameservers = lib.mkForce [ "127.0.0.1" ];

  zramSwap = {
    enable = true;
    memoryPercent = 25; # ~4 GB of compressed swap
  };

  networking.interfaces.enp3s0.wakeOnLan.enable = true;

}
