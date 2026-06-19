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

    # Home Assistant runs as root (official image), like jellyfin — only needs
    # the config dir to exist; root writes regardless of ownership.
    "d /mnt/storage/k3s/config/homeassistant 0755 root root -"
    "d /mnt/storage/k3s/config/homeassistant/config 0755 root root -"

    # Directories needing linuxserver ownership (Z = recursive chown)
    "d /mnt/storage/k3s/config/torrent 0755 ${puid} ${pgid} -"
    "Z /mnt/storage/k3s/config/torrent 0755 ${puid} ${pgid} -"
    "d /mnt/storage/k3s/config/seerr 0755 ${puid} ${pgid} -"
    "Z /mnt/storage/k3s/config/seerr 0755 ${puid} ${pgid} -"

    # CouchDB (obsidian livesync) runs as uid/gid 5984; the data dir must be
    # pre-owned since the non-root container can't chown the hostPath itself.
    "d /mnt/storage/k3s/config/obsidian 0755 5984 5984 -"
    "d /mnt/storage/k3s/config/obsidian/data 0755 5984 5984 -"
    "Z /mnt/storage/k3s/config/obsidian 0755 5984 5984 -"

    # Mosquitto runs as uid/gid 1883 (non-root securityContext). hostPath
    # volumes ignore the pod's fsGroup, so the data/log dirs must be pre-owned
    # or the broker can't write its persistence DB and log.
    "d /mnt/storage/k3s/config/mosquitto 0755 1883 1883 -"
    "d /mnt/storage/k3s/config/mosquitto/data 0755 1883 1883 -"
    "d /mnt/storage/k3s/config/mosquitto/log 0755 1883 1883 -"
    "Z /mnt/storage/k3s/config/mosquitto 0755 1883 1883 -"
  ];
}
