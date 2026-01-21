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
  
  programs.zsh.shellAliases.os-rebuild = "sudo nixos-rebuild switch --flake $DOTFILES/nix#workstation";

# Mount Windows ESP so systemd-boot can chainload it
  fileSystems."/boot/windows" = {
    device = "/dev/disk/by-uuid/7E62-7861";
    fsType = "vfat";
    options = [ "ro" "nofail" ];
  };

# Add Windows boot entry
  boot.loader.systemd-boot.extraEntries = {
    "windows.conf" = ''
      title Windows
      efi /windows/EFI/Microsoft/Boot/bootmgfw.efi
    '';
  };
}
