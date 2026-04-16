# Kubernetes manifests for the media stack
# All resources declared as Nix attrsets, deployed atomically with nixos-rebuild switch
{ config, pkgs, lib, ... }:

let
  tz = "Europe/Berlin";
  puid = "1000";
  pgid = "1000";
  mediaNamespace = "media";
  homelabIp = "192.168.0.121";

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

  # Simple single-container Deployment with best practices
  mkDeployment = {
    name, image,
    env ? [], ports ? [], volumeMounts ? [], volumes ? [],
    extraSpec ? {},
    livenessProbe ? null,
    readinessProbe ? null,
    resources ? null,
    securityContext ? null,
  }:
    let
      container = { inherit name image env ports volumeMounts; }
        // lib.optionalAttrs (livenessProbe != null) { inherit livenessProbe; }
        // lib.optionalAttrs (readinessProbe != null) { inherit readinessProbe; }
        // lib.optionalAttrs (resources != null) { inherit resources; }
        // lib.optionalAttrs (securityContext != null) { inherit securityContext; };
    in {
      apiVersion = "apps/v1";
      kind = "Deployment";
      metadata = { inherit name; namespace = mediaNamespace; };
      spec = {
        replicas = 1;
        strategy.type = "Recreate";
        selector.matchLabels.app = name;
        template = {
          metadata.labels.app = name;
          spec = {
            containers = [ container ];
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

  # HTTP probe helper
  httpProbe = path: port: {
    httpGet = { inherit path port; };
    initialDelaySeconds = 30;
    periodSeconds = 30;
    timeoutSeconds = 5;
  };

  # TCP probe helper
  tcpProbe = port: {
    tcpSocket = { inherit port; };
    initialDelaySeconds = 30;
    periodSeconds = 30;
    timeoutSeconds = 5;
  };
in
{
  # Ensure media directories exist with correct ownership for linuxserver containers
  systemd.tmpfiles.rules = [
    "d /mnt/storage/media 0755 ${puid} ${pgid} -"
    "d /mnt/storage/media/tv 0755 ${puid} ${pgid} -"
    "d /mnt/storage/media/movies 0755 ${puid} ${pgid} -"
    "d /mnt/storage/media/downloads 0755 ${puid} ${pgid} -"
    "Z /mnt/storage/media/downloads 0755 ${puid} ${pgid} -"
    "d /mnt/storage/k3s/config/torrent 0755 ${puid} ${pgid} -"
    "Z /mnt/storage/k3s/config/torrent 0755 ${puid} ${pgid} -"
  ];

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
      image = "lscr.io/linuxserver/jellyfin:10.11.8ubu2404-ls28";
      env = lsioEnv ++ [
        { name = "LD_LIBRARY_PATH"; value = "/usr/local/nvidia/lib64"; }
        { name = "NVIDIA_VISIBLE_DEVICES"; value = "all"; }
        { name = "NVIDIA_DRIVER_CAPABILITIES"; value = "all"; }
      ];
      ports = [{ containerPort = 8096; }];
      livenessProbe = httpProbe "/health" 8096;
      readinessProbe = httpProbe "/health" 8096;
      resources = {
        requests = { cpu = "500m"; memory = "512Mi"; };
        limits = { cpu = "4000m"; memory = "4Gi"; };
      };
      volumeMounts = [
        (mount "config" "/config")
        (mount "media" "/media")
        (mount "dev-dri" "/dev/dri")
        (mount "nvidia0" "/dev/nvidia0")
        (mount "nvidiactl" "/dev/nvidiactl")
        (mount "nvidia-uvm" "/dev/nvidia-uvm")
        (mount "nvidia-libs" "/usr/local/nvidia/lib64")
      ];
      volumes = [
        (hostVol "config" "/mnt/storage/k3s/config/jellyfin")
        (hostVol "media" "/mnt/storage/media")
        (hostVol "dev-dri" "/dev/dri")
        { name = "nvidia0"; hostPath = { path = "/dev/nvidia0"; }; }
        { name = "nvidiactl"; hostPath = { path = "/dev/nvidiactl"; }; }
        { name = "nvidia-uvm"; hostPath = { path = "/dev/nvidia-uvm"; }; }
        { name = "nvidia-libs"; hostPath = { path = "/run/opengl-driver/lib"; type = "Directory"; }; }
      ];
      extraSpec.securityContext.privileged = true;
    };

    jellyfin-svc.content = mkService "jellyfin" 8096;

    # ── Torrent client (qBittorrent + gluetun VPN sidecar) ───────────────────
    # gluetun and qbittorrent share the same pod network namespace.
    # gluetun sets iptables DROP rules for non-VPN traffic — kill switch built-in.
    torrent.content = {
      apiVersion = "apps/v1";
      kind = "Deployment";
      metadata = { name = "torrent"; namespace = mediaNamespace; };
      spec = {
        replicas = 1;
        strategy.type = "Recreate";
        selector.matchLabels.app = "torrent";
        template = {
          metadata.labels.app = "torrent";
          spec = {
            containers = [
              {
                name = "gluetun";
                image = "qmcgaw/gluetun:v3.41.1";
                securityContext.capabilities.add = [ "NET_ADMIN" ];
                resources = {
                  requests = { cpu = "50m"; memory = "64Mi"; };
                  limits = { cpu = "500m"; memory = "256Mi"; };
                };
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
                  # ProtonVPN blocks ICMP — use DNS healthcheck instead
                  { name = "HEALTH_SMALL_CHECK_TYPE"; value = "dns"; }
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
                image = "lscr.io/linuxserver/qbittorrent:5.1.4-r3-ls450";
                env = lsioEnv ++ [
                  { name = "WEBUI_PORT"; value = "8080"; }
                ];
                resources = {
                  requests = { cpu = "100m"; memory = "256Mi"; };
                  limits = { cpu = "1000m"; memory = "1Gi"; };
                };
                livenessProbe = tcpProbe 8080;
                readinessProbe = tcpProbe 8080;
                securityContext.allowPrivilegeEscalation = false;
                # No ports — shares gluetun's network namespace
                volumeMounts = [
                  (mount "qbt-config" "/config")
                  (mount "downloads" "/downloads")
                ];
              }
            ];
            volumes = [
              (hostVol "gluetun-config" "/mnt/storage/k3s/config/gluetun")
              (hostVol "qbt-config" "/mnt/storage/k3s/config/torrent")
              (hostVol "downloads" "/mnt/storage/media/downloads")
            ];
          };
        };
      };
    };

    torrent-svc.content = mkService "torrent" 8080;

    # ── Sonarr ─────────────────────────────────────────────────────────────────
    sonarr.content = mkDeployment {
      name = "sonarr";
      image = "lscr.io/linuxserver/sonarr:4.0.17.2952-ls307";
      env = lsioEnv;
      ports = [{ containerPort = 8989; }];
      livenessProbe = httpProbe "/ping" 8989;
      readinessProbe = httpProbe "/ping" 8989;
      resources = {
        requests = { cpu = "100m"; memory = "256Mi"; };
        limits = { cpu = "1000m"; memory = "1Gi"; };
      };
      securityContext.allowPrivilegeEscalation = false;
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
      image = "lscr.io/linuxserver/radarr:6.1.1.10360-ls299";
      env = lsioEnv;
      ports = [{ containerPort = 7878; }];
      livenessProbe = httpProbe "/ping" 7878;
      readinessProbe = httpProbe "/ping" 7878;
      resources = {
        requests = { cpu = "100m"; memory = "256Mi"; };
        limits = { cpu = "1000m"; memory = "1Gi"; };
      };
      securityContext.allowPrivilegeEscalation = false;
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
      image = "lscr.io/linuxserver/prowlarr:2.3.5.5327-ls142";
      env = lsioEnv;
      ports = [{ containerPort = 9696; }];
      livenessProbe = httpProbe "/ping" 9696;
      readinessProbe = httpProbe "/ping" 9696;
      resources = {
        requests = { cpu = "50m"; memory = "128Mi"; };
        limits = { cpu = "500m"; memory = "512Mi"; };
      };
      securityContext.allowPrivilegeEscalation = false;
      volumeMounts = [(mount "config" "/config")];
      volumes = [(hostVol "config" "/mnt/storage/k3s/config/prowlarr")];
    };

    prowlarr-svc.content = mkService "prowlarr" 9696;

    # ── Bazarr ─────────────────────────────────────────────────────────────────
    bazarr.content = mkDeployment {
      name = "bazarr";
      image = "lscr.io/linuxserver/bazarr:v1.5.6-ls344";
      env = lsioEnv;
      ports = [{ containerPort = 6767; }];
      livenessProbe = tcpProbe 6767;
      readinessProbe = tcpProbe 6767;
      resources = {
        requests = { cpu = "50m"; memory = "128Mi"; };
        limits = { cpu = "500m"; memory = "512Mi"; };
      };
      securityContext.allowPrivilegeEscalation = false;
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
      image = "ghcr.io/seerr-team/seerr:v3.2.0";
      env = [{ name = "LOG_LEVEL"; value = "debug"; }];
      ports = [{ containerPort = 5055; }];
      livenessProbe = tcpProbe 5055;
      readinessProbe = tcpProbe 5055;
      resources = {
        requests = { cpu = "100m"; memory = "256Mi"; };
        limits = { cpu = "1000m"; memory = "1Gi"; };
      };
      securityContext.allowPrivilegeEscalation = false;
      volumeMounts = [(mount "config" "/app/config")];
      volumes = [(hostVol "config" "/mnt/storage/k3s/config/jellyseerr")];
    };

    jellyseerr-svc.content = mkService "jellyseerr" 5055;

    # ── Flaresolverr ───────────────────────────────────────────────────────────
    flaresolverr.content = mkDeployment {
      name = "flaresolverr";
      image = "ghcr.io/flaresolverr/flaresolverr:v3.4.6";
      env = [{ name = "LOG_LEVEL"; value = "info"; }];
      ports = [{ containerPort = 8191; }];
      livenessProbe = httpProbe "/health" 8191;
      readinessProbe = httpProbe "/health" 8191;
      resources = {
        requests = { cpu = "100m"; memory = "256Mi"; };
        limits = { cpu = "1000m"; memory = "1Gi"; };
      };
      securityContext.allowPrivilegeEscalation = false;
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
                  href: http://jellyfin.jcing.de
                  icon: jellyfin.png
                  description: Media server
              - Jellyseerr:
                  href: http://jellyseerr.jcing.de
                  icon: jellyseerr.png
                  description: Media requests
          - Management:
              - Sonarr:
                  href: http://sonarr.jcing.de
                  icon: sonarr.png
                  description: TV shows
              - Radarr:
                  href: http://radarr.jcing.de
                  icon: radarr.png
                  description: Movies
              - Prowlarr:
                  href: http://prowlarr.jcing.de
                  icon: prowlarr.png
                  description: Indexers
              - Bazarr:
                  href: http://bazarr.jcing.de
                  icon: bazarr.png
                  description: Subtitles
          - Downloads:
              - qBittorrent:
                  href: http://torrent.jcing.de
                  icon: qbittorrent.png
                  description: Torrent client (VPN)
          - Infrastructure:
              - Adguard Home:
                  href: http://adguard.jcing.de
                  icon: adguard-home.png
                  description: DNS & ad blocker
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
        strategy.type = "Recreate";
        selector.matchLabels.app = "homepage";
        template = {
          metadata.labels.app = "homepage";
          spec = {
            containers = [{
              name = "homepage";
              image = "ghcr.io/gethomepage/homepage:v1.12.3";
              ports = [{ containerPort = 3000; }];
              env = [
                { name = "HOMEPAGE_ALLOWED_HOSTS"; value = "homepage.jcing.de,${homelabIp}"; }
              ];
              livenessProbe = httpProbe "/" 3000;
              readinessProbe = httpProbe "/" 3000;
              resources = {
                requests = { cpu = "50m"; memory = "64Mi"; };
                limits = { cpu = "500m"; memory = "256Mi"; };
              };
              securityContext.allowPrivilegeEscalation = false;
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

    # ── Adguard Home (external service — runs on host, not in k3s) ─────────────
    adguard-svc.content = {
      apiVersion = "v1";
      kind = "Service";
      metadata = { name = "adguard"; namespace = mediaNamespace; };
      spec.ports = [{ port = 3380; targetPort = 3380; }];
    };

    adguard-endpoints.content = {
      apiVersion = "v1";
      kind = "Endpoints";
      metadata = { name = "adguard"; namespace = mediaNamespace; };
      subsets = [{
        addresses = [{ ip = homelabIp; }];
        ports = [{ port = 3380; }];
      }];
    };

    # ── Traefik Ingress (LAN access to all service UIs) ──────────────────────
    # k3s bundles Traefik — these are available out of the box
    media-ingress.content = {
      apiVersion = "networking.k8s.io/v1";
      kind = "Ingress";
      metadata = {
        name = "media-ingress";
        namespace = mediaNamespace;
        annotations."traefik.ingress.kubernetes.io/router.entrypoints" = "web";
      };
      spec.rules = map (svc: {
        host = "${svc.name}.jcing.de";
        http.paths = [{
          path = "/";
          pathType = "Prefix";
          backend.service = {
            name = svc.name;
            port.number = svc.port;
          };
        }];
      }) [
        { name = "jellyfin";     port = 8096; }
        { name = "sonarr";       port = 8989; }
        { name = "radarr";       port = 7878; }
        { name = "prowlarr";     port = 9696; }
        { name = "bazarr";       port = 6767; }
        { name = "jellyseerr";   port = 5055; }
        { name = "torrent";      port = 8080; }
        { name = "flaresolverr"; port = 8191; }
        { name = "homepage";     port = 3000; }
        { name = "adguard";      port = 3380; }
      ];
    };

  };
}
