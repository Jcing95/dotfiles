# Workstation-specific configuration
{ config, pkgs, username, ... }:

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

  users.users.${username}.extraGroups = [ "corectrl" ];
}
