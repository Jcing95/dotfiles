{ pkgs, ... }:

let
  device = "/dev/v4l/by-id/usb-Anker_PowerConf_C200_Anker_PowerConf_C200_ACNV9P1F52308526-video-index0";
  zoom = 256;

  applyZoom = pkgs.writeShellScript "anker-c200-apply-zoom" ''
    set -u
    DEV="${device}"
    while true; do
      while [ ! -e "$DEV" ]; do sleep 2; done

      ${pkgs.v4l-utils}/bin/v4l2-ctl -d "$DEV" --set-ctrl=zoom_absolute=${toString zoom} 2>/dev/null || true

      ${pkgs.inotify-tools}/bin/inotifywait -m -q -e open -e close_write "$DEV" 2>/dev/null \
        | while read -r _; do
            sleep 0.3
            ${pkgs.v4l-utils}/bin/v4l2-ctl -d "$DEV" --set-ctrl=zoom_absolute=${toString zoom} 2>/dev/null || true
          done

      sleep 1
    done
  '';
in
{
  services.udev.extraRules = ''
    ACTION=="add|change", SUBSYSTEM=="video4linux", ATTRS{idVendor}=="291a", ATTRS{idProduct}=="3369", ATTR{index}=="0", RUN+="${pkgs.v4l-utils}/bin/v4l2-ctl -d $devnode --set-ctrl=zoom_absolute=${toString zoom}"
  '';

  systemd.services.anker-c200-zoom = {
    description = "Re-apply Anker PowerConf C200 zoom on every device open";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udev-settle.service" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${applyZoom}";
      Restart = "always";
      RestartSec = 2;
    };
  };
}
