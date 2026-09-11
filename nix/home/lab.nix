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

  home.file.".config/hypr/host.lua".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/hypr/lab.lua";

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

  # ── GPU performance, scoped to the desktop session ────────────────────────
  # The GTX 980 sits in PowerMizer "Adaptive" (mode 0), whose ramp heuristic is
  # driven by X11 rendering notifications. There is no X server here, so a
  # Wayland compositor's EGL/GBM load never triggers it and the card stays
  # pinned at its minimum P8 clocks: 135 MHz core / 324 MHz memory out of
  # 1455/3505, i.e. ~10 GB/s of memory bandwidth instead of 224. That is enough
  # to make even a 1920x1080@60 composite miss frame deadlines while every
  # utilisation counter still reads idle -- util% is relative to the *current*
  # clocks, so a GPU crawling at 135 MHz looks unused while it drops frames.
  #
  # Mode 1 ("prefer maximum performance") takes it to P0/P2; measured on lab,
  # 135 -> 1189 MHz core and 324 -> 3505 MHz memory, with GPU utilisation for
  # the same desktop load falling from 17% to 2%. It costs roughly 20-30 W of
  # extra idle draw, which is why it is tied to the session rather than set at
  # boot: lab is headless by default (systemd.defaultUnit = multi-user.target,
  # modules/server.nix) and only runs a desktop between `tv-on` and `tv-off`.
  #
  # ExecStop is load-bearing, not decorative. nvidia-settings reaches the driver
  # directly rather than through X -- it applies correctly with DISPLAY unset
  # entirely -- so the setting outlives the compositor and has to be reverted
  # explicitly, or the GPU would stay boosted, and burning the extra watts,
  # after tv-off.
  #
  # nvidia-settings comes from /run/current-system/sw/bin (provided by
  # hardware.nvidia.nvidiaSettings in modules/nvidia-lab.nix) rather than a pkgs
  # path, so it always matches the running driver instead of whatever version a
  # separate Home Manager closure would pull in.
  systemd.user.services.nvidia-powermizer = {
    Unit = {
      Description = "NVIDIA PowerMizer: maximum performance while a graphical session is up";
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "/run/current-system/sw/bin/nvidia-settings -a [gpu:0]/GPUPowerMizerMode=1";
      ExecStop = "/run/current-system/sw/bin/nvidia-settings -a [gpu:0]/GPUPowerMizerMode=0";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
