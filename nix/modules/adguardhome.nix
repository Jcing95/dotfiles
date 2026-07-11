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
        # Disable per-client query rate limiting. The default (20 q/s) silently
        # drops bursts, which breaks apps that fire many lookups at once — e.g.
        # StarCraft 2 map/lobby downloads crawl and time out. This resolver is
        # LAN-only (firewall opens 53 to the local network, not the internet),
        # so the anti-amplification limit serves no purpose here.
        ratelimit = 0;
      };
      filtering = {
        # Wildcard: every *.jcing.de subdomain is served by Traefik on the lab
        # node, so point them all at it. New apps resolve with no rebuild.
        # NB: does not match the apex (jcing.de) — left to public DNS so the
        # website/email keep resolving normally from the LAN.
        rewrites = [
          { domain = "*.jcing.de"; answer = "192.168.0.121"; enabled = true; }
        ];
      };
    };
  };

  networking.firewall = {
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = [ 53 ];
  };
}
