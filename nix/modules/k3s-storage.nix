# Storage directory structure for k3s workloads
# Ensures correct ownership for linuxserver containers (PUID/PGID 1000)
{ config, pkgs, lib, ... }:

let
  puid = "1000";
  pgid = "1000";
in
{
  systemd.tmpfiles.rules = [
    # Media directories (owned by linuxserver PUID/PGID)
    "d /mnt/storage/media 0755 ${puid} ${pgid} -"
    "d /mnt/storage/media/movies 0755 ${puid} ${pgid} -"
    "d /mnt/storage/media/tv 0755 ${puid} ${pgid} -"
    "d /mnt/storage/media/downloads 0755 ${puid} ${pgid} -"
    "d /mnt/storage/media/downloads/complete 0775 root root -"
    "d /mnt/storage/media/downloads/incomplete 0775 root root -"
    "Z /mnt/storage/media/downloads 0755 ${puid} ${pgid} -"

    # k3s config directories
    "d /mnt/storage/k3s 0755 root root -"
    "d /mnt/storage/k3s/config 0755 root root -"
    "d /mnt/storage/k3s/config/jellyfin 0755 root root -"
    "d /mnt/storage/k3s/config/sonarr 0755 root root -"
    "d /mnt/storage/k3s/config/radarr 0755 root root -"
    "d /mnt/storage/k3s/config/prowlarr 0755 root root -"
    "d /mnt/storage/k3s/config/bazarr 0755 root root -"
    "d /mnt/storage/k3s/config/flaresolverr 0755 root root -"
    "d /mnt/storage/k3s/config/homepage 0755 root root -"
    "d /mnt/storage/k3s/config/gluetun 0755 root root -"

    # Directories needing linuxserver ownership (Z = recursive chown)
    "d /mnt/storage/k3s/config/torrent 0755 ${puid} ${pgid} -"
    "Z /mnt/storage/k3s/config/torrent 0755 ${puid} ${pgid} -"
    "d /mnt/storage/k3s/config/seerr 0755 ${puid} ${pgid} -"
    "Z /mnt/storage/k3s/config/seerr 0755 ${puid} ${pgid} -"
  ];
}
