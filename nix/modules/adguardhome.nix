# Adguard Home — local DNS resolver + ad blocker
# Resolves *.lab to the homelab IP, forwards everything else to Cloudflare
{ config, pkgs, ... }:

{
  services.adguardhome = {
    enable = true;
    mutableSettings = true;
    settings = {
      http = {
        address = "0.0.0.0:3380";
      };
      dns = {
        bind_hosts = [ "0.0.0.0" ];
        port = 53;
        upstream_dns = [ "1.1.1.1" "1.0.0.1" ];
        bootstrap_dns = [ "1.1.1.1" "1.0.0.1" ];
        rewrites = [
          { domain = "*.lab"; answer = "192.168.0.121"; }
        ];
      };
    };
  };

  networking.firewall = {
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = [ 53 ];
  };
}
