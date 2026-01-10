# Laptop-specific configuration
{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/core.nix
    ../../modules/desktop.nix
    ../../modules/audio.nix
    ../../modules/nvidia.nix
  ];

  networking.hostName = "laptop";

  # Windows dual-boot: set Windows as default boot option
  boot.loader.systemd-boot.extraInstallCommands = ''
    ${pkgs.gnused}/bin/sed -i 's/^default .*/default auto-windows/' /boot/loader/loader.conf
  '';
  
  programs.zsh.shellAliases.os-rebuild = "sudo nixos-rebuild switch --flake $DOTFILES/nix#laptop";
}
