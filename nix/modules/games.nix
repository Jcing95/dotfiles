# Game servers running in k3s.
#
# One file per concern so adding or dropping a game is a single edit: the port here
# and the app entry in homelab-charts' apps/values.yaml. Ports are opened on all
# interfaces — LAN players connect straight to 192.168.0.121, remote players arrive
# via the VPS's nftables DNAT over tailscale0.
{ ... }:

let
  puid = "1000";
  pgid = "1000";
in
{
  networking.firewall.allowedTCPPorts = [
    21025 # Starbound (game protocol is TCP-only; 21026 is RCON, not enabled)
  ];

  # Server state lives on the SSD tier alongside the other k3s app configs. Same
  # pre-owned-hostPath pattern as torrent/seerr in modules/k3s-storage.nix: hostPath
  # volumes ignore the pod's fsGroup, so the dir must already belong to the runtime uid.
  systemd.tmpfiles.rules = [
    "d /mnt/storage/k3s/config/starbound 0755 ${puid} ${pgid} -"
    "Z /mnt/storage/k3s/config/starbound 0755 ${puid} ${pgid} -"
  ];
}
