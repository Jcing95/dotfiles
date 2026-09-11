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

  # Use local Adguard Home for DNS (overrides core.nix Cloudflare defaults)
  # Adguard Home rewrites *.jcing.de → 192.168.0.121, no /etc/hosts needed
  networking.nameservers = lib.mkForce [ "127.0.0.1" ];
  networking.networkmanager.insertNameservers = lib.mkForce [ "127.0.0.1" ];

  # lab runs a desktop and a ~30-pod k3s cluster on 16 GB with no swap device
  # (hardware-configuration.nix: swapDevices = [ ]), which left ~3.3 GB
  # available and k8s memory limits overcommitted to 206%. zram gives the
  # kernel somewhere to put cold anonymous pages without touching the SSD.
  # Paired with --kubelet-arg=fail-swap-on=false in modules/k3s.nix: kubelet
  # still refuses to start on a swap-enabled node by default, so enabling
  # zram without that flag would take the cluster down on the next rebuild.
  zramSwap = {
    enable = true;
    memoryPercent = 25; # ~4 GB of compressed swap
  };

  # Enable Wake on LAN on Ethernet
  networking.interfaces.enp3s0.wakeOnLan.enable = true;

}
