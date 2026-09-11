# NVIDIA GPU configuration for lab — single discrete GTX 980 (Maxwell)
# Drives the display over HDMI and provides H.264 NVENC for Jellyfin transcoding.
# No Intel/prime offload here (unlike the laptop's nvidia.nix) — this is the only GPU.
{ config, pkgs, ... }:

{
  boot.kernelModules = [ "nvidia" ];
  boot.kernelPackages = pkgs.linuxPackages_latest;

  environment.variables = {
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

      # Also provides /run/current-system/sw/bin/nvidia-settings, which the
      # nvidia-powermizer user unit in ../home/lab.nix uses to force the card out
      # of its minimum P8 clocks for the duration of a desktop session. Adaptive
      # PowerMizer never ramps under Wayland (no X server to drive its
      # heuristic), so without that unit the desktop renders at 135 MHz.
      nvidiaSettings = true;

      # Keeps the driver resident so the GPU is not torn down and re-initialised
      # between clients — this is what cuts NVENC start-up latency for Jellyfin.
      # Note it has no effect on clocks or P-states: persistence is about the
      # driver staying loaded, not the GPU staying boosted. Clock behaviour is
      # PowerMizer's job, handled by the nvidia-powermizer unit described above.
      nvidiaPersistenced = true;

      # 580 legacy branch — last branch supporting Maxwell; production/590+ dropped it
      package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
    };
  };
}
