# Laptop-specific configuration
{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/core.nix
    ../../modules/server.nix
    ../../modules/audio.nix
    ../../modules/nvidia.nix
    ../../modules/sshd.nix
  ];

  networking.hostName = "homelab";

  # Allow laptop to stay on with lid closed (connected to external display)
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchDocked = "ignore";
    HandleLidSwitchExternalPower = "ignore";
  };

  # Windows dual-boot: set Windows as default boot option
  # boot.loader.systemd-boot.extraInstallCommands = ''
  #   ${pkgs.gnused}/bin/sed -i 's/^default .*/default auto-windows/' /boot/loader/loader.conf
  # '';
  
  programs.zsh.shellAliases = {
    os-rebuild = "sudo nixos-rebuild switch --flake $DOTFILES/nix#laptop";
    tv-on = "sudo systemctl start greetd";
    tv-off = "sudo systemctl stop greetd";
  };
}
