# k3s single-node cluster infrastructure
{ config, pkgs, lib, ... }:

{
  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = toString [
      "--write-kubeconfig-mode=644"
    ];
  };

  environment.systemPackages = with pkgs; [
    kubectl
    kubernetes-helm
    k9s
  ];

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    # IPv6 forwarding intentionally NOT enabled at host level.
    # k3s runs IPv4-only; gluetun handles IPv6 inside the container via ip6tables.
  };

  networking.firewall.allowedTCPPorts = [ 80 443 8096 ];

  # Storage directory structure for all services
  systemd.tmpfiles.rules = [
    "d /mnt/storage/media 0775 root root -"
    "d /mnt/storage/media/movies 0775 root root -"
    "d /mnt/storage/media/tv 0775 root root -"
    "d /mnt/storage/media/downloads 0775 root root -"
    "d /mnt/storage/media/downloads/complete 0775 root root -"
    "d /mnt/storage/media/downloads/incomplete 0775 root root -"
    "d /mnt/storage/k3s 0755 root root -"
    "d /mnt/storage/k3s/config 0755 root root -"
    "d /mnt/storage/k3s/config/jellyfin 0755 root root -"
    "d /mnt/storage/k3s/config/sonarr 0755 root root -"
    "d /mnt/storage/k3s/config/radarr 0755 root root -"
    "d /mnt/storage/k3s/config/prowlarr 0755 root root -"
    "d /mnt/storage/k3s/config/bazarr 0755 root root -"
    "d /mnt/storage/k3s/config/torrent 0755 root root -"
    "d /mnt/storage/k3s/config/gluetun 0755 root root -"
    "d /mnt/storage/k3s/config/jellyseerr 0755 root root -"
    "d /mnt/storage/k3s/config/flaresolverr 0755 root root -"
    "d /mnt/storage/k3s/config/homepage 0755 root root -"
  ];

  # Bridge sops-decrypted secrets into Kubernetes after k3s starts
  systemd.services.k3s-create-secrets = {
    description = "Create Kubernetes secrets from sops-decrypted files";
    after = [ "k3s.service" "sops-nix.service" ];
    wants = [ "k3s.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.kubectl ];
    script = ''
      export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
      until kubectl get namespace media 2>/dev/null; do sleep 2; done
      kubectl create secret generic protonvpn-credentials \
        --namespace=media \
        --from-file=wireguard-private-key=${config.sops.secrets."protonvpn/wireguard-private-key".path} \
        --dry-run=client -o yaml | kubectl apply -f -
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };
}
