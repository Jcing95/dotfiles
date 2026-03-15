# NVIDIA GPU configuration (for laptop with Intel + NVIDIA in Offload Mode)
# Allows GPU to fully power down in headless mode
{ config, pkgs, ... }:

{
  # Kernel modules
  boot.kernelModules = [ "nvidia" ];
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Environment variables for Wayland + NVIDIA offload (system-wide)
  environment.variables = {
    XDG_SESSION_TYPE = "wayland";
    # NVIDIA offload - apps use NVIDIA when started, GPU powers down when idle
    __NV_PRIME_RENDER_OFFLOAD = "1";
    __NV_PRIME_RENDER_OFFLOAD_PROVIDER = "NVIDIA-G0";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    __VK_LAYER_NV_optimus = "NVIDIA_only";
    LIBVA_DRIVER_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    # Hyprland cursor fix
    WLR_NO_HARDWARE_CURSORS = "1";
    AQ_NO_HARDWARE_CURSORS = "1";
  };

  # NVIDIA drivers
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware = {
    graphics.enable = true;
    nvidia = {
      modesetting.enable = true;

      # Power management for suspend/resume and GPU power-off
      powerManagement.enable = true;
      powerManagement.finegrained = true;

      # Offload mode: Intel primary, NVIDIA powers down when unused
      prime = {
        offload.enable = true;
        offload.enableOffloadCmd = true;  # Provides nvidia-offload wrapper

        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };

      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };
}
