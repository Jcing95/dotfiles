# Cloudflare Tunnel daemon configuration
{ config, pkgs, ... }:

let
  tokenPath = config.sops.secrets."cloudflared/tunnel-token".path;
in
{
  environment.systemPackages = [ pkgs.cloudflared ];

  systemd.services.cloudflared = {
    description = "Cloudflare Tunnel";
    after = [ "network-online.target" "sops-nix.service" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    script = ''
      ${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run --token $(cat ${tokenPath})
    '';
    serviceConfig = {
      Type = "simple";
      Restart = "on-failure";
      RestartSec = 5;
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
    };
  };
}
