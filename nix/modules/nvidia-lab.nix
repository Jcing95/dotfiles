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

    # Route VAAPI/VDPAU through NVDEC so browsers and players hardware-decode
    # video instead of falling back to CPU software decode (the playback stutter).
    LIBVA_DRIVER_NAME = "nvidia";
    VDPAU_DRIVER = "nvidia";
    NVD_BACKEND = "direct"; # nvidia-vaapi-driver: talk to NVDEC directly, not via X11
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware = {
    graphics = {
      enable = true;
      # VAAPI -> NVDEC bridge (nvidia-vaapi-driver) plus VDPAU fallbacks, so
      # browser/Jellyfin video decode runs on the GPU. 32-bit libs for Steam
      # come from programs.steam (enable32Bit).
      extraPackages = with pkgs; [
        nvidia-vaapi-driver
        libva-vdpau-driver
        libvdpau-va-gl
      ];
    };
    nvidia = {
      modesetting.enable = true;

      # Power management for suspend/resume
      powerManagement.enable = true;
      powerManagement.finegrained = false;

      # Maxwell predates the open kernel modules (Turing+), keep the proprietary one
      open = false;
      nvidiaSettings = true;

      # Keep the driver resident so the GPU doesn't cold-start its clocks on
      # every app launch — reduces latency-spike stutter when video/games begin.
      nvidiaPersistenced = true;

      # 580 legacy branch — last branch supporting Maxwell; production/590+ dropped it
      package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
    };
  };
}
