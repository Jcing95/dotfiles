# Home Manager configuration for homelab
{ pkgs, ... }:

{
  imports = [
    ./linux.nix
  ];

  programs.zsh.shellAliases = {
    tv-on = "sudo systemctl start greetd";
    tv-off = "sudo systemctl stop greetd";
  };

  home.sessionVariables.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";

  home.file.".config/hypr/host.conf".source = ../../hypr/homelab.conf;

  home.packages = with pkgs; [
    brave
    spotify
    claude-code
    ssh-to-age
    sops
  ];

  home.pointerCursor.size = 24;
}
