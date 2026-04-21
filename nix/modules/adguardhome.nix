# Adguard Home — local DNS resolver + ad blocker
# Fully declarative — config is overwritten on every rebuild.
# Manage filter lists and rewrites here, not via the web UI.
{ config, pkgs, ... }:

{
  services.adguardhome = {
    enable = true;
    port = 3380;
    host = "0.0.0.0";
    mutableSettings = false;
    settings = {
      schema_version = 33;
      dns = {
        bind_hosts = [ "0.0.0.0" ];
        port = 53;
        upstream_dns = [ "1.1.1.1" "1.0.0.1" ];
        bootstrap_dns = [ "1.1.1.1" "1.0.0.1" ];
      };
      filtering = {
        rewrites = [
          { domain = "jellyfin.jcing.de";     answer = "192.168.0.121"; enabled = true; }
          { domain = "sonarr.jcing.de";       answer = "192.168.0.121"; enabled = true; }
          { domain = "radarr.jcing.de";       answer = "192.168.0.121"; enabled = true; }
          { domain = "prowlarr.jcing.de";     answer = "192.168.0.121"; enabled = true; }
          { domain = "bazarr.jcing.de";       answer = "192.168.0.121"; enabled = true; }
          { domain = "seerr.jcing.de";        answer = "192.168.0.121"; enabled = true; }
          { domain = "torrent.jcing.de";      answer = "192.168.0.121"; enabled = true; }
          { domain = "flaresolverr.jcing.de"; answer = "192.168.0.121"; enabled = true; }
          { domain = "homepage.jcing.de";     answer = "192.168.0.121"; enabled = true; }
          { domain = "adguard.jcing.de";      answer = "192.168.0.121"; enabled = true; }
          { domain = "argocd.jcing.de";      answer = "192.168.0.121"; enabled = true; }
        ];
      };
    };
  };

  networking.firewall = {
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = [ 53 ];
  };
}
