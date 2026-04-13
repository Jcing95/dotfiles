# Home Manager configuration for homelab
{ pkgs, ... }:

{
  imports = [
    ./linux.nix
  ];

  home.file.".config/hypr/host.conf".source = ../../hypr/homelab.conf;

  home.packages = with pkgs; [
    brave
    spotify
    claude-code
  ];

  home.pointerCursor.size = 24;
}
