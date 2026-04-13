# sops-nix secrets management
{ config, pkgs, ... }:

{
  sops = {
    defaultSopsFile = ../secrets/homelab.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    secrets."cloudflared/tunnel-token" = {};
  };
}
