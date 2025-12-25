# NVIDIA GPU configuration (for laptop with Intel + NVIDIA)
{ config, pkgs, ... }:

{
  # Kernel modules
  boot.kernelModules = [ "nvidia" ];
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Environment variables for NVIDIA on Wayland
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  # NVIDIA drivers
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware = {
    graphics.enable = true;
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      
      # Prime offload for hybrid graphics
      prime = {
        offload.enable = true;
        offload.enableOffloadCmd = true;
        intelBusId = "PCI:00:02:0";
        nvidiaBusId = "PCI:01:00:0";
      };

      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };
}
