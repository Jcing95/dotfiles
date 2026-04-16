# Workstation-specific configuration
{ config, pkgs, lib, username, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/core.nix
    ../../modules/desktop.nix
    ../../modules/audio.nix
    ../../modules/amd.nix
    ../../modules/goxlr.nix
  ];

  networking.hostName = "workstation";

  # Use homelab Adguard Home for DNS — resolves *.jcing.de + ad blocking
  networking.nameservers = lib.mkForce [ "192.168.0.121" "1.1.1.1" ];
  networking.networkmanager.insertNameservers = lib.mkForce [ "192.168.0.121" "1.1.1.1" ];

  users.users.${username}.extraGroups = [ "corectrl" ];
}
