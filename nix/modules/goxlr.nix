# GoXLR Mini configuration
{ config, pkgs, ... }:

{
  
  services.goxlr-utility = {
    enable = true;
    autoStart.xdg = true;
  };
  
  systemd.user.services = {
    goxlr-set-default = {
      description = "Set GoXLR System as default sink";
      after = [ 
        "pipewire-pulse.service"
        "goxlr-utility.service"
      ];
      requires = [ "goxlr-utility.service" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.pulseaudio}/bin/pactl set-default-sink alsa_output.usb-TC-Helicon_GoXLRMini-00.HiFi__Speaker__sink";
        RemainAfterExit = true;
      };
    };
  };
}
