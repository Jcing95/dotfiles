# AMD GPU configuration (for workstation)
{ config, pkgs, ... }:

{
  boot.kernelModules = [ "amdgpu" ];
  boot.kernelPackages = pkgs.linuxPackages_latest;

  services.xserver.videoDrivers = [ "amdgpu" ];

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
    ];
  };
}
