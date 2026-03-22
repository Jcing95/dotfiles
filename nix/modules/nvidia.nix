# NVIDIA GPU configuration (for laptop with Intel + NVIDIA in Offload Mode)
# Intel is primary, NVIDIA only used when explicitly requested via nvidia-offload
{ config, pkgs, ... }:

{
  # Kernel modules
  boot.kernelModules = [ "nvidia" ];
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Only cursor fix needed system-wide, Intel handles everything else by default
  environment.variables = {
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
