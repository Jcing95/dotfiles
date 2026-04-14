# sops-nix secrets management
{ config, pkgs, ... }:

let
  sshKeyPath = "/etc/ssh/ssh_host_ed25519_key";
  ageKeyPath = "/etc/sops/age/keys.txt";
in
{
  sops = {
    defaultSopsFile = ../secrets/homelab.yaml;

    age = {
      keyFile = null;
      sshKeyPaths = [ sshKeyPath ];
    };

    secrets."cloudflared/tunnel-token" = {};
  };

  # Derive age key from SSH host key for standalone sops CLI usage
  system.activationScripts.sopsAgeKey.text = ''
    mkdir -p /etc/sops/age
    ${pkgs.ssh-to-age}/bin/ssh-to-age -private-key -i ${sshKeyPath} -o ${ageKeyPath}
    chmod 400 ${ageKeyPath}
  '';

  environment.variables.SOPS_AGE_KEY_FILE = ageKeyPath;
}
