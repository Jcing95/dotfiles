# Home Manager configuration for macbook
{ pkgs, ... }:

{
  imports = [
    ./home-modules/git.nix
  ];

  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    github-copilot-cli
  ];

  home.file.".aerospace.toml".source = ../aerospace.toml;
  home.file.".config/wezterm".source = ../wezterm;
  home.file.".config/nvim".source = ../lazyvim;
  # Nextcloud needs a writable/accessible config file, not a nix store symlink
  home.file."Library/Preferences/Nextcloud/nextcloud.cfg".text = builtins.readFile ../nextcloud.cfg;
  
  programs.starship.enable = true;
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  programs.home-manager.enable = true;
}
