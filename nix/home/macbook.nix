# Home Manager configuration for macbook
{ pkgs, username, ... }:

let
  oms = pkgs.callPackage ../pkgs/oms.nix {};

  sketchybarConfig = pkgs.stdenvNoCC.mkDerivation {
    name = "sketchybar-config";
    src = ../../darwin/sketchybar;
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out
      cp -r $src/* $out/
      find $out -name '*.sh' -exec chmod +x {} \;
      chmod +x $out/sketchybarrc
    '';
  };
in
{
  imports = [
    ./common.nix
  ];

  home.username = username;
  home.homeDirectory = "/Users/${username}";
  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    github-copilot-cli
    oms
    google-cloud-sdk
    cloudflared
  ];

  # Dotfile symlinks
  home.file.".config/wezterm".source = ../../wezterm;
  home.file.".config/nvim".source = ../../lazyvim;

  # Sketchybar config (deployed with executable permissions)
  home.file.".config/sketchybar".source = sketchybarConfig;

  programs.starship.enable = true;
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  programs.home-manager.enable = true;
}
