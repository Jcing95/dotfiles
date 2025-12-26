# Workstation-specific configuration
{ config, pkgs, ... }:

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
  
  programs.zsh.shellAliases.os-rebuild = "sudo nixos-rebuild switch --flake ~/dotfiles/nix#laptop";
}
