# k3s single-node cluster infrastructure + ArgoCD bootstrap
{ config, pkgs, lib, ... }:

let
  # TODO: Update this to your private repo URL
  argocdRepoUrl = "git@github.com:Jcing95/homelab-charts.git";
in
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

  # 1883: MQTT broker (mosquitto runs hostNetwork, so it listens on the node's
  # LAN IP). Without this open, LAN smart devices (Tasmota, etc.) can't reach it.
  networking.firewall.allowedTCPPorts = [ 80 443 8096 1883 ];

  # Let k3s CNI (flannel) pod/service traffic through the host firewall.
  # Without this, the enabled NixOS firewall drops pod -> API ClusterIP
  # (10.43.0.1) traffic, so a nixos-rebuild leaves pods unable to reach the
  # API and ArgoCD stops reconciling. Trusting the CNI interfaces (and loose
  # reverse-path, which flannel/VXLAN needs) keeps cluster networking working
  # across rebuilds.
  networking.firewall.trustedInterfaces = [ "cni0" "flannel.1" ];
  networking.firewall.checkReversePath = "loose";

  # ── ArgoCD installation via k3s built-in Helm controller ──────────────────
  services.k3s.manifests = {
    # Let Traefik preserve the X-Forwarded-For it receives instead of
    # overwriting it with the peer address.
    #
    # Every request reaches Traefik from a klipper svclb pod, because servicelb
    # DNATs the hostPort to the Traefik ClusterIP and then MASQUERADEs
    # (`-A POSTROUTING -d <traefik-clusterip>/32 -p tcp -j MASQUERADE`). So the
    # peer is always 10.42.x.x and the original client address only survives in
    # the header. Traefik's default trustedIPs is empty, which makes it *strip*
    # untrusted X-Forwarded-* and substitute the peer — so without this, the real
    # client IP set by the VPS's Caddy is destroyed before Immich or anything
    # else sees it. Trusting the pod CIDR restores it, and Immich's own default
    # (['linklocal','uniquelocal'], which covers 10/8) then resolves it correctly
    # with no app-side config.
    #
    # Only `web` is configured: every Ingress pins router.entrypoints=web, and
    # nothing terminates TLS in-cluster. The trade-off is that any pod could
    # forge X-Forwarded-For — acceptable on a single-tenant homelab, and the
    # standard way to run Traefik behind a LoadBalancer that masquerades.
    #
    # readTimeout: Traefik's built-in default is 60s and it covers "reading the
    # entire request, including the body" (`traefik --help`). That silently kills
    # any upload whose body takes longer than a minute to transfer — a large
    # Immich video over a normal uplink — and the client just sees a gateway
    # error, with Traefik logging 499. It never showed up before because
    # Cloudflare's 100 MB cap kept uploads short; removing that cap is exactly
    # what exposed it.
    #
    # Set to 0 (no limit) rather than a bigger finite number: this entrypoint is
    # not directly internet-facing (the VPS's Caddy fronts it, LAN/tailnet
    # otherwise), and any finite value is just a slower cliff to rediscover.
    # idleTimeout stays at its 180s default, so dead keep-alive connections are
    # still reaped.
    traefik-forwarded-headers.content = {
      apiVersion = "helm.cattle.io/v1";
      kind = "HelmChartConfig";
      metadata = {
        name = "traefik";
        namespace = "kube-system";
      };
      spec.valuesContent = ''
        ports:
          web:
            forwardedHeaders:
              trustedIPs:
                - 10.42.0.0/16
            transport:
              respondingTimeouts:
                readTimeout: 0
      '';
    };

    argocd-namespace.content = {
      apiVersion = "v1";
      kind = "Namespace";
      metadata.name = "argocd";
    };

    argocd-install.content = {
      apiVersion = "helm.cattle.io/v1";
      kind = "HelmChart";
      metadata = {
        name = "argocd";
        namespace = "kube-system";
      };
      spec = {
        repo = "https://argoproj.github.io/argo-helm";
        chart = "argo-cd";
        targetNamespace = "argocd";
        createNamespace = true;
        valuesContent = ''
          server:
            service:
              type: ClusterIP
            ingress:
              enabled: true
              hostname: argocd.jcing.de
              annotations:
                traefik.ingress.kubernetes.io/router.entrypoints: web
          # Helm repositories the umbrella charts in homelab-charts depend on.
          # ArgoCD renders those charts with `helm dependency build`, which only
          # knows the repos registered here (it runs helm with its own
          # repository config, not a shared one). Without these entries the build
          # fails with "no repository definition for <url>", the render errors,
          # and -- since the charts are no longer vendored as .tgz in git -- the
          # chart cannot be rendered at all.
          configs:
            params:
              server.insecure: true
            repositories:
              immich-charts:
                name: immich-charts
                type: helm
                url: https://immich-app.github.io/immich-charts
              bjw-s:
                name: bjw-s
                type: helm
                url: https://bjw-s-labs.github.io/helm-charts
        '';
      };
    };

    # AdGuard runs on the host (services.adguardhome, :3380), not in-cluster.
    # The adguard-external chart ships a selector-less Service, but ArgoCD's
    # resource.exclusions drop Endpoints/EndpointSlice, so it can never create
    # the backing endpoints. Define the EndpointSlice here (outside ArgoCD's
    # blind spot) so Traefik has a backend to route adguard.jcing.de to.
    # Traefik reaches :3380 via the trusted cni0 interface (no firewall change).
    adguard-endpointslice.content = {
      apiVersion = "discovery.k8s.io/v1";
      kind = "EndpointSlice";
      metadata = {
        name = "adguard-external";
        namespace = "infra";
        labels."kubernetes.io/service-name" = "adguard";
      };
      addressType = "IPv4";
      # Empty port name matches the adguard Service's single unnamed port.
      ports = [
        { name = ""; port = 3380; protocol = "TCP"; }
      ];
      endpoints = [
        {
          addresses = [ "192.168.0.121" ];
          conditions.ready = true;
        }
      ];
    };
  };

  # ── Bootstrap ArgoCD root application after CRD is available ────────────
  systemd.services.k3s-bootstrap-argocd = {
    description = "Bootstrap ArgoCD root application";
    after = [ "k3s.service" ];
    wants = [ "k3s.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.kubectl ];
    script = ''
      export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

      # Wait for ArgoCD Application CRD to be registered
      until kubectl get crd applications.argoproj.io 2>/dev/null; do sleep 5; done
      sleep 10

      # Create repo credentials secret (SSH deploy key from sops)
      # Use kubectl create secret to avoid YAML parsing issues with SSH key delimiters
      kubectl create secret generic homelab-charts-repo \
        --namespace=argocd \
        --from-literal=type=git \
        --from-literal=url="${argocdRepoUrl}" \
        --from-file=sshPrivateKey=${config.sops.secrets."argocd/ssh-deploy-key".path} \
        --dry-run=client -o yaml \
        | kubectl label --local -f - argocd.argoproj.io/secret-type=repository -o yaml \
        | kubectl apply -f -

      # Apply the root app-of-apps Application
      kubectl apply -f - <<YAML
      apiVersion: argoproj.io/v1alpha1
      kind: Application
      metadata:
        name: homelab-root
        namespace: argocd
      spec:
        project: default
        source:
          repoURL: "${argocdRepoUrl}"
          targetRevision: main
          path: apps
        destination:
          server: https://kubernetes.default.svc
          namespace: argocd
        syncPolicy:
          automated:
            prune: true
            selfHeal: true
          syncOptions:
            - CreateNamespace=true
      YAML
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

  # ── Bridge sops-decrypted secrets into Kubernetes ─────────────────────────
  systemd.services.k3s-create-secrets = {
    description = "Create Kubernetes secrets from sops-decrypted files";
    after = [ "k3s.service" "sops-nix.service" ];
    wants = [ "k3s.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.kubectl ];
    script = ''
      export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
      # Apps are split into per-area namespaces (all pre-created by the ArgoCD
      # root app). Wait for each namespace before applying its secrets.
      until kubectl get namespace media 2>/dev/null; do sleep 2; done
      kubectl create secret generic protonvpn-credentials \
        --namespace=media \
        --from-file=wireguard-private-key=${config.sops.secrets."protonvpn/wireguard-private-key".path} \
        --dry-run=client -o yaml | kubectl apply -f -

      until kubectl get namespace home 2>/dev/null; do sleep 2; done
      kubectl create secret generic mosquitto-passwd \
        --namespace=home \
        --from-file=passwd=${config.sops.secrets."mosquitto/passwd".path} \
        --dry-run=client -o yaml | kubectl apply -f -

      until kubectl get namespace obsidian 2>/dev/null; do sleep 2; done
      kubectl create secret generic obsidian-couchdb \
        --namespace=obsidian \
        --from-file=COUCHDB_USER=${config.sops.secrets."obsidian/couchdb-user".path} \
        --from-file=COUCHDB_PASSWORD=${config.sops.secrets."obsidian/couchdb-password".path} \
        --dry-run=client -o yaml | kubectl apply -f -
      kubectl create secret generic telegram-bot \
        --namespace=obsidian \
        --from-file=BOT_TOKEN=${config.sops.secrets."telegram/bot-token".path} \
        --from-file=ALLOWED_USER_ID=${config.sops.secrets."telegram/allowed-user-id".path} \
        --dry-run=client -o yaml | kubectl apply -f -

      # Immich runs in its own namespace (created by the ArgoCD root app), so
      # wait for it before applying the DB password secret.
      until kubectl get namespace immich 2>/dev/null; do sleep 2; done
      kubectl create secret generic immich-postgres \
        --namespace=immich \
        --from-file=POSTGRES_PASSWORD=${config.sops.secrets."immich/postgres-password".path} \
        --dry-run=client -o yaml | kubectl apply -f -
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };
}
