# Home Manager configuration for lab
{ config, pkgs, ... }:

let
  dotfiles = "${config.home.homeDirectory}/dotfiles";
in
{
  imports = [
    ./linux.nix
  ];

  programs.zsh.shellAliases = {
    tv-on = "sudo systemctl start greetd";
    tv-off = "sudo systemctl stop greetd";
  };

  home.sessionVariables.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";

  home.file.".config/hypr/host.lua".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/hypr/homelab.lua";

  home.packages = with pkgs; [
    # Force-enable VAAPI on NVIDIA: Chromium blocklists the NVIDIA VAAPI device
    # by default ("Should skip nVidia device named: nvidia-drm"), so the GTX 980's
    # NVDEC is unused. VaapiOnNvidiaGPUs lifts that guard. NVDEC only does H.264,
    # so an h264ify-style extension is still required for VP9/AV1 sites (YouTube).
    (brave.override {
      commandLineArgs = "--enable-features=VaapiOnNvidiaGPUs,AcceleratedVideoDecodeLinuxGL,AcceleratedVideoEncoder";
    })
    spotify
    claude-code
    ssh-to-age
    sops
  ];

  home.pointerCursor.size = 24;
}
