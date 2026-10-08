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
    (brave.override {
      commandLineArgs = "--enable-features=VaapiOnNvidiaGPUs,AcceleratedVideoDecodeLinuxGL,AcceleratedVideoEncoder";
    })
    ssh-to-age
    sops
  ];

  home.pointerCursor.size = 24;

  # Adaptive PowerMizer only ramps in response to X11 rendering notifications, so
  # under Wayland the GTX 980 stays pinned at its minimum 135 MHz / 324 MHz clocks
  # and the desktop drops frames while every utilisation counter reads idle.
  #
  # Mode 1 lifts it to P0, but the driver drops the override a few seconds after
  # the nvidia-settings client exits, hence the re-apply loop instead of a
  # one-shot. `nvidia-smi -lgc` would be the clean way to pin clocks; Maxwell
  # predates locked-clock support and reports it unsupported.
  #
  # DISPLAY must be set or nvidia-settings aborts with "control display is
  # undefined", even though it reaches the driver directly and tolerates the
  # display not actually existing (which is what covers the Xwayland startup race).
  #
  # No ExecStop: the override lapses by itself once re-application stops, so the
  # card falls back to P8 when the session ends.
  systemd.user.services.nvidia-powermizer = {
    Unit = {
      Description = "NVIDIA PowerMizer: maximum performance while a graphical session is up";
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      Environment = "DISPLAY=:0";
      ExecStart = pkgs.writeShellScript "nvidia-powermizer" ''
        while :; do
          /run/current-system/sw/bin/nvidia-settings -a '[gpu:0]/GPUPowerMizerMode=1' >/dev/null 2>&1 || true
          sleep 4
        done
      '';
      Restart = "always";
      RestartSec = 5;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
