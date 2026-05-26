{ pkgs, ... }:

{
  services.udev.extraRules = ''
    ACTION=="add|change", SUBSYSTEM=="video4linux", ATTRS{idVendor}=="291a", ATTRS{idProduct}=="3369", ENV{ID_V4L_CAPABILITIES}=="*:capture:*", RUN+="${pkgs.v4l-utils}/bin/v4l2-ctl -d $devnode --set-ctrl=zoom_absolute=256"
  '';
}
