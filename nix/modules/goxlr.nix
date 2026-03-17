# GoXLR Mini configuration
{ config, pkgs, ... }:

{

  services.goxlr-utility = {
    enable = true;
    autoStart.xdg = false;  # Disable XDG autostart, we use systemd instead
  };

  systemd.user.services = {
    # Custom systemd service for goxlr-daemon (since the module only supports XDG autostart)
    goxlr-daemon = {
      description = "GoXLR Utility Daemon";
      after = [ "pipewire.service" "pipewire-pulse.service" ];
      wants = [ "pipewire.service" ];
      wantedBy = [ "default.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.goxlr-utility}/bin/goxlr-daemon";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };

    goxlr-set-default = {
      description = "Set GoXLR System as default sink";
      after = [
        "pipewire-pulse.service"
        "goxlr-daemon.service"
      ];
      requires = [ "goxlr-daemon.service" ];
      wantedBy = [ "default.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";  # Give daemon time to register sinks
        ExecStart = "${pkgs.pulseaudio}/bin/pactl set-default-sink alsa_output.usb-TC-Helicon_GoXLRMini-00.HiFi__Speaker__sink";
        RemainAfterExit = true;
      };
    };
  };
}
