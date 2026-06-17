# NVIDIA GPU configuration for lab — single discrete GTX 980 (Maxwell)
# Drives the display over HDMI and provides H.264 NVENC for Jellyfin transcoding.
# No Intel/prime offload here (unlike the laptop's nvidia.nix) — this is the only GPU.
{ config, pkgs, ... }:

{
  boot.kernelModules = [ "nvidia" ];
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Cursor fix for wlroots/Hyprland
  environment.variables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    AQ_NO_HARDWARE_CURSORS = "1";
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware = {
    graphics.enable = true;
    nvidia = {
      modesetting.enable = true;

      # Power management for suspend/resume
      powerManagement.enable = true;
      powerManagement.finegrained = false;

      # Maxwell predates the open kernel modules (Turing+), keep the proprietary one
      open = false;
      nvidiaSettings = true;

      # 580 legacy branch — last branch supporting Maxwell; production/590+ dropped it
      package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
    };
  };
}
