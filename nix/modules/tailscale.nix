# Tailscale mesh — connects lab to the public VPS that fronts immich/jellyfin/games.
#
# The VPS terminates TLS (Caddy + Let's Encrypt) and reverse-proxies to Traefik on
# this node over the tailnet, replacing the Cloudflare Tunnel for the hostnames that
# hit its 100 MB proxied-upload cap. Game servers reach this node the same way, via
# nftables DNAT on the VPS.
{ config, ... }:

{
  services.tailscale = {
    enable = true;
    authKeyFile = config.sops.secrets."tailscale/auth-key".path;

    # Defaults to false. Without it every connection falls back to a DERP relay
    # instead of going direct, which costs latency and throughput on the
    # jellyfin/immich path.
    openFirewall = true;

    # Redundant with networking.hostName, but pins the node name the tailnet ACL
    # and the VPS Caddyfile refer to.
    extraUpFlags = [ "--hostname=lab" ];
  };

  # Deliberately NOT adding tailscale0 to networking.firewall.trustedInterfaces.
  # The VPS is the internet-facing box; trusting the whole tailnet would hand it
  # the k3s API (6443), sshd and AdGuard if it were ever compromised. Port 80 is
  # already open on all interfaces (modules/k3s.nix), which is all the Caddy path
  # needs; game ports are opened individually in modules/games.nix. Scope the rest
  # with a tailnet ACL in the Tailscale admin console.
}
