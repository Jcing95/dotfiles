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
    ../../modules/herdr.nix
  ];

  # home/common.nix already installs brave for every host, so adding a second,
  # differently-configured brave to home.packages collides in buildEnv. Override the
  # package instead: the VAAPI flags are what the GTX 980 needs for hardware decode.
  nixpkgs.overlays = [
    (final: prev: {
      brave = prev.brave.override {
        commandLineArgs = "--enable-features=VaapiOnNvidiaGPUs,AcceleratedVideoDecodeLinuxGL,AcceleratedVideoEncoder";
      };
    })
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
