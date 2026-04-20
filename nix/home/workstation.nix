# Home Manager configuration for workstation
{ pkgs, ... }:

{
  imports = [
    ./linux.nix
  ];

  # Nextcloud needs a writable config file, not a nix store symlink
  home.file.".config/Nextcloud/nextcloud.cfg".text = builtins.readFile ../../nextcloud.cfg;
  home.file.".config/hypr/host.conf".source = ../../hypr/workstation.conf;

  home.packages = with pkgs; [
    brave
    telegram-desktop
    discord
    spotify
    prismlauncher
    nextcloud-client
    claude-code
    bolt-launcher
    runelite
    devenv
    hueadm
    heroic
    lutris
    bottles
    umu-launcher
  ];

  home.pointerCursor.size = 36;
}
