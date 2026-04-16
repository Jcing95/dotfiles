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

      # Power management for suspend/resume
      powerManagement.enable = true;
      powerManagement.finegrained = false;

      # Sync mode: both GPUs always on — needed for Jellyfin NVENC transcoding
      prime = {
        sync.enable = true;

        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };

      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
    };
  };
}
