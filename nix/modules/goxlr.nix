# GoXLR Mini configuration
{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    goxlr-utility
  ];

  systemd.user.services = {
    goxlr-utility = {
      description = "GoXLR Utility";
      wantedBy = [ "graphical-session.target" ];
      after = [ "graphical-session.target" "pipewire.service" ];
      serviceConfig = {
        ExecStart = "${pkgs.goxlr-utility}/bin/goxlr-daemon";
        Restart = "always";
        RestartSec = "5s";
      };
    };

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
