# Kubernetes manifests for the media stack
# All resources declared as Nix attrsets, deployed atomically with nixos-rebuild switch
{ config, pkgs, lib, ... }:

let
  tz = "Europe/Berlin";
  puid = "1000";
  pgid = "1000";
  mediaNamespace = "media";

  # Common linuxserver env vars
  lsioEnv = [
    { name = "PUID"; value = puid; }
    { name = "PGID"; value = pgid; }
    { name = "TZ"; value = tz; }
  ];

  # hostPath volume helper
  hostVol = name: path: {
    inherit name;
    hostPath = { inherit path; type = "DirectoryOrCreate"; };
  };

  # volumeMount helper
  mount = name: mountPath: { inherit name mountPath; };

  # Simple single-container Deployment
  mkDeployment = { name, image, env ? [], ports ? [], volumeMounts ? [], volumes ? [], extraSpec ? {} }:
    {
      apiVersion = "apps/v1";
      kind = "Deployment";
      metadata = { inherit name; namespace = mediaNamespace; };
      spec = {
        replicas = 1;
        selector.matchLabels.app = name;
        template = {
          metadata.labels.app = name;
          spec = {
            containers = [{
              inherit name image env ports volumeMounts;
            }];
            inherit volumes;
          } // extraSpec;
        };
      };
    };

  # ClusterIP Service
  mkService = name: port: {
    apiVersion = "v1";
    kind = "Service";
    metadata = { inherit name; namespace = mediaNamespace; };
    spec = {
      selector.app = name;
      ports = [{ inherit port; targetPort = port; }];
    };
  };
in
{
  services.k3s.manifests = {

    # ── Namespace ──────────────────────────────────────────────────────────────
    media-namespace.content = {
      apiVersion = "v1";
      kind = "Namespace";
      metadata.name = mediaNamespace;
    };

    # ── Jellyfin ───────────────────────────────────────────────────────────────
    jellyfin.content = mkDeployment {
      name = "jellyfin";
      image = "lscr.io/linuxserver/jellyfin:latest";
      env = lsioEnv;
      ports = [{ containerPort = 8096; }];
      volumeMounts = [
        (mount "config" "/config")
        (mount "media" "/media")
        (mount "dev-dri" "/dev/dri")
      ];
      volumes = [
        (hostVol "config" "/mnt/storage/k3s/config/jellyfin")
        (hostVol "media" "/mnt/storage/media")
        (hostVol "dev-dri" "/dev/dri")
      ];
      extraSpec.securityContext.privileged = true;
    };

    jellyfin-svc.content = mkService "jellyfin" 8096;

    # ── Download client (qBittorrent + gluetun VPN sidecar) ───────────────────
    # gluetun and qbittorrent share the same pod network namespace.
    # gluetun sets iptables DROP rules for non-VPN traffic — kill switch built-in.
    download-client.content = {
      apiVersion = "apps/v1";
      kind = "Deployment";
      metadata = { name = "download-client"; namespace = mediaNamespace; };
      spec = {
        replicas = 1;
        selector.matchLabels.app = "download-client";
        template = {
          metadata.labels.app = "download-client";
          spec = {
            containers = [
              {
                name = "gluetun";
                image = "qmcgaw/gluetun:latest";
                securityContext.capabilities.add = [ "NET_ADMIN" ];
                env = [
                  # Custom WireGuard provider — uses exact NL#908 config from ProtonVPN dashboard.
                  # This is more reliable than the protonvpn provider mode which uses API
                  # server discovery and can pick servers the key pair isn't registered for.
                  { name = "VPN_SERVICE_PROVIDER"; value = "custom"; }
                  { name = "VPN_TYPE"; value = "wireguard"; }
                  {
                    name = "WIREGUARD_PRIVATE_KEY";
                    valueFrom.secretKeyRef = {
                      name = "protonvpn-credentials";
                      key = "wireguard-private-key";
                    };
                  }
                  { name = "WIREGUARD_ADDRESSES"; value = "10.2.0.2/32,2a07:b944::2:2/128"; }
                  { name = "WIREGUARD_PUBLIC_KEY"; value = "8x7Y1OT1WRtShqk4lk3KbqpnPftTZLCpVu4VxRT/dzQ="; }
                  { name = "WIREGUARD_ENDPOINT_IP"; value = "169.150.196.69"; }
                  { name = "WIREGUARD_ENDPOINT_PORT"; value = "51820"; }
                  # Use ProtonVPN's tunnel DNS — no DNS-over-TLS needed
                  { name = "DNS_ADDRESS"; value = "10.2.0.1"; }
                  # Allow inbound connections to qBittorrent webui from the cluster
                  { name = "FIREWALL_INPUT_PORTS"; value = "8080"; }
                  { name = "TZ"; value = tz; }
                ];
                ports = [
                  { containerPort = 8080; name = "webui"; }
                ];
                volumeMounts = [
                  (mount "gluetun-config" "/gluetun")
                ];
              }
              {
                name = "qbittorrent";
                image = "lscr.io/linuxserver/qbittorrent:latest";
                env = lsioEnv ++ [
                  { name = "WEBUI_PORT"; value = "8080"; }
                ];
                # No ports — shares gluetun's network namespace
                volumeMounts = [
                  (mount "qbt-config" "/config")
                  (mount "downloads" "/downloads")
                ];
              }
            ];
            volumes = [
              (hostVol "gluetun-config" "/mnt/storage/k3s/config/gluetun")
              (hostVol "qbt-config" "/mnt/storage/k3s/config/qbittorrent")
              (hostVol "downloads" "/mnt/storage/media/downloads")
            ];
          };
        };
      };
    };

    download-client-svc.content = mkService "download-client" 8080;

    # ── Sonarr ─────────────────────────────────────────────────────────────────
    sonarr.content = mkDeployment {
      name = "sonarr";
      image = "lscr.io/linuxserver/sonarr:latest";
      env = lsioEnv;
      ports = [{ containerPort = 8989; }];
      volumeMounts = [
        (mount "config" "/config")
        (mount "media" "/media")
      ];
      volumes = [
        (hostVol "config" "/mnt/storage/k3s/config/sonarr")
        (hostVol "media" "/mnt/storage/media")
      ];
    };

    sonarr-svc.content = mkService "sonarr" 8989;

    # ── Radarr ─────────────────────────────────────────────────────────────────
    radarr.content = mkDeployment {
      name = "radarr";
      image = "lscr.io/linuxserver/radarr:latest";
      env = lsioEnv;
      ports = [{ containerPort = 7878; }];
      volumeMounts = [
        (mount "config" "/config")
        (mount "media" "/media")
      ];
      volumes = [
        (hostVol "config" "/mnt/storage/k3s/config/radarr")
        (hostVol "media" "/mnt/storage/media")
      ];
    };

    radarr-svc.content = mkService "radarr" 7878;

    # ── Prowlarr ───────────────────────────────────────────────────────────────
    prowlarr.content = mkDeployment {
      name = "prowlarr";
      image = "lscr.io/linuxserver/prowlarr:latest";
      env = lsioEnv;
      ports = [{ containerPort = 9696; }];
      volumeMounts = [(mount "config" "/config")];
      volumes = [(hostVol "config" "/mnt/storage/k3s/config/prowlarr")];
    };

    prowlarr-svc.content = mkService "prowlarr" 9696;

    # ── Bazarr ─────────────────────────────────────────────────────────────────
    bazarr.content = mkDeployment {
      name = "bazarr";
      image = "lscr.io/linuxserver/bazarr:latest";
      env = lsioEnv;
      ports = [{ containerPort = 6767; }];
      volumeMounts = [
        (mount "config" "/config")
        (mount "media" "/media")
      ];
      volumes = [
        (hostVol "config" "/mnt/storage/k3s/config/bazarr")
        (hostVol "media" "/mnt/storage/media")
      ];
    };

    bazarr-svc.content = mkService "bazarr" 6767;

    # ── Jellyseerr ─────────────────────────────────────────────────────────────
    jellyseerr.content = mkDeployment {
      name = "jellyseerr";
      image = "fallenbagel/jellyseerr:latest";
      env = [{ name = "LOG_LEVEL"; value = "debug"; }];
      ports = [{ containerPort = 5055; }];
      volumeMounts = [(mount "config" "/app/config")];
      volumes = [(hostVol "config" "/mnt/storage/k3s/config/jellyseerr")];
    };

    jellyseerr-svc.content = mkService "jellyseerr" 5055;

    # ── Flaresolverr ───────────────────────────────────────────────────────────
    flaresolverr.content = mkDeployment {
      name = "flaresolverr";
      image = "ghcr.io/flaresolverr/flaresolverr:latest";
      env = [{ name = "LOG_LEVEL"; value = "info"; }];
      ports = [{ containerPort = 8191; }];
      volumeMounts = [];
      volumes = [];
    };

    flaresolverr-svc.content = mkService "flaresolverr" 8191;

    # ── Homepage dashboard ─────────────────────────────────────────────────────
    homepage-config.content = {
      apiVersion = "v1";
      kind = "ConfigMap";
      metadata = { name = "homepage-config"; namespace = mediaNamespace; };
      data = {
        "settings.yaml" = ''
          title: Homelab
          theme: dark
          color: slate
        '';
        "services.yaml" = ''
          - Media:
              - Jellyfin:
                  href: http://jellyfin:8096
                  icon: jellyfin.png
              - Jellyseerr:
                  href: http://jellyseerr:5055
                  icon: jellyseerr.png
          - Management:
              - Sonarr:
                  href: http://sonarr:8989
                  icon: sonarr.png
              - Radarr:
                  href: http://radarr:7878
                  icon: radarr.png
              - Prowlarr:
                  href: http://prowlarr:9696
                  icon: prowlarr.png
              - Bazarr:
                  href: http://bazarr:6767
                  icon: bazarr.png
          - Downloads:
              - qBittorrent:
                  href: http://download-client:8080
                  icon: qbittorrent.png
        '';
        "widgets.yaml" = "[]";
        "bookmarks.yaml" = "[]";
      };
    };

    homepage.content = {
      apiVersion = "apps/v1";
      kind = "Deployment";
      metadata = { name = "homepage"; namespace = mediaNamespace; };
      spec = {
        replicas = 1;
        selector.matchLabels.app = "homepage";
        template = {
          metadata.labels.app = "homepage";
          spec = {
            containers = [{
              name = "homepage";
              image = "ghcr.io/gethomepage/homepage:latest";
              ports = [{ containerPort = 3000; }];
              env = [
                { name = "HOMEPAGE_ALLOWED_HOSTS"; value = "homepage.homelab.local"; }
              ];
              volumeMounts = [
                { name = "config"; mountPath = "/app/config"; }
                { name = "config-files"; mountPath = "/app/config/services.yaml"; subPath = "services.yaml"; }
                { name = "config-files"; mountPath = "/app/config/settings.yaml"; subPath = "settings.yaml"; }
                { name = "config-files"; mountPath = "/app/config/widgets.yaml"; subPath = "widgets.yaml"; }
                { name = "config-files"; mountPath = "/app/config/bookmarks.yaml"; subPath = "bookmarks.yaml"; }
              ];
            }];
            volumes = [
              (hostVol "config" "/mnt/storage/k3s/config/homepage")
              { name = "config-files"; configMap.name = "homepage-config"; }
            ];
          };
        };
      };
    };

    homepage-svc.content = mkService "homepage" 3000;

    # ── Traefik IngressRoutes (LAN access to all service UIs) ─────────────────
    # k3s bundles Traefik — these CRDs are available out of the box
    traefik-middleware.content = {
      apiVersion = "traefik.io/v1alpha1";
      kind = "Middleware";
      metadata = { name = "strip-prefix"; namespace = mediaNamespace; };
      spec.stripPrefix.prefixes = [ "/" ];
    };

    ingress-jellyfin.content = {
      apiVersion = "networking.k8s.io/v1";
      kind = "Ingress";
      metadata = {
        name = "media-ingress";
        namespace = mediaNamespace;
        annotations."traefik.ingress.kubernetes.io/router.entrypoints" = "web";
      };
      spec.rules = map (svc: {
        host = "${svc.name}.homelab.local";
        http.paths = [{
          path = "/";
          pathType = "Prefix";
          backend.service = {
            name = svc.name;
            port.number = svc.port;
          };
        }];
      }) [
        { name = "jellyfin";       port = 8096; }
        { name = "sonarr";         port = 8989; }
        { name = "radarr";         port = 7878; }
        { name = "prowlarr";       port = 9696; }
        { name = "bazarr";         port = 6767; }
        { name = "jellyseerr";     port = 5055; }
        { name = "download-client"; port = 8080; }
        { name = "flaresolverr";   port = 8191; }
        { name = "homepage";       port = 3000; }
      ];
    };

  };
}
