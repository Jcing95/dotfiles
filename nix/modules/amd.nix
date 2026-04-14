# AMD GPU configuration (for workstation)
{ config, pkgs, ... }:

{
  boot.kernelModules = [ "amdgpu" ];
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [
    "amdgpu.ppfeaturemask=0xffffffff"
  ];

  services.xserver.videoDrivers = [ "amdgpu" ];

  hardware.enableRedistributableFirmware = true;

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
    ];
  };
  hardware.amdgpu.overdrive.enable = true;

  programs.corectrl = {
    enable = true;
  };
}
