# USB device access for ZMK keyboards
# Grants the user access to:
#   - ZMK Studio control protocol (CDC ACM, running firmware) — via dialout group
#   - Adafruit nRF52 bootloader (DFU mode, used by nice!nano for flashing .uf2) — via uaccess
{ username, ... }:

{
  users.users.${username}.extraGroups = [ "dialout" ];

  services.udev.extraRules = ''
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="239a", ATTRS{idProduct}=="0029", TAG+="uaccess"
  '';
}
