# Hostnames for homelab services — import on any machine that needs access
{ ... }:

{
  networking.hosts."192.168.0.121" = [
    "jellyfin.homelab.local"
    "sonarr.homelab.local"
    "radarr.homelab.local"
    "prowlarr.homelab.local"
    "bazarr.homelab.local"
    "jellyseerr.homelab.local"
    "download-client.homelab.local"
    "flaresolverr.homelab.local"
    "homepage.homelab.local"
  ];
}
