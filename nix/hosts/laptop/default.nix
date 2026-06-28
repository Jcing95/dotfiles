# Laptop-specific configuration
{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/core.nix
    ../../modules/neovim.nix
    ../../modules/desktop.nix
    ../../modules/fonts.nix
    ../../modules/audio.nix
    ../../modules/nvidia.nix
  ];

  networking.hostName = "laptop";

  # Use lab's Adguard Home for DNS — resolves *.jcing.de + ad blocking on the
  # home network, with Cloudflare as a fallback when roaming off-LAN.
  networking.nameservers = lib.mkForce [ "192.168.0.121" "1.1.1.1" ];
  networking.networkmanager.insertNameservers = lib.mkForce [ "192.168.0.121" "1.1.1.1" ];
}
