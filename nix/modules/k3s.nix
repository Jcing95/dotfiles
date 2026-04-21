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

  networking.firewall.allowedTCPPorts = [ 80 443 8096 ];

  # ── ArgoCD installation via k3s built-in Helm controller ──────────────────
  services.k3s.manifests = {
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
          configs:
            params:
              server.insecure: true
        '';
      };
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
