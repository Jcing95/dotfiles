# Workstation-specific configuration
{ config, pkgs, lib, username, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/core.nix
    ../../modules/neovim.nix
    ../../modules/desktop.nix
    ../../modules/fonts.nix
    ../../modules/audio.nix
    ../../modules/amd.nix
    ../../modules/goxlr.nix
    ../../modules/docker.nix
    ../../modules/zmk.nix
    ../../modules/webcam.nix
  ];

  networking.hostName = "workstation";

  # DNS: the lab AdGuard is the *primary* resolver — it serves the *.jcing.de
  # rewrites and ad-blocks everything else. Enabling systemd-resolved lets us
  # keep 1.1.1.1 as a true FallbackDNS (only consulted when the lab is
  # unreachable), instead of a co-equal nameserver that would race LAN-only
  # hosts like adguard.jcing.de to NXDOMAIN.
  services.resolved = {
    enable = true;
    settings.Resolve.FallbackDNS = [ "1.1.1.1" "1.0.0.1" ];
  };
  networking.nameservers = lib.mkForce [ "192.168.0.121" ];
  networking.networkmanager.insertNameservers = lib.mkForce [ "192.168.0.121" ];

  users.users.${username}.extraGroups = [ "corectrl" ];
}
