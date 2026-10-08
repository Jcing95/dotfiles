# Force a DP re-probe while no display is attached to the Navi 31 (03:00.0)
#
# The G95NC is an MST sink: the physical port stays "disconnected" and the scanout
# connector is a virtual one that only exists once topology discovery has run. When the
# monitor is powered on after boot that discovery sometimes never fires, leaving the
# screen black until a reboot. Writing "detect" to a connector's status forces a full
# re-probe, which restarts discovery and makes udev announce the new connector.
{ pkgs, ... }:

let
  gpu = "0000:03:00.0";

  rescan = pkgs.writeShellScript "dp-hotplug-rescan" ''
    set -u
    UDEVADM=${pkgs.systemd}/bin/udevadm

    # Addressed by PCI path: card numbering follows probe order and is not stable.
    connectors() {
      for c in /sys/bus/pci/devices/${gpu}/drm/card*/card*-*; do
        case "$c" in *-Writeback-*) continue ;; esac
        [ -e "$c/status" ] || continue
        printf '%s\n' "$c"
      done
    }

    connected() {
      for c in $(connectors); do
        if [ "$(cat "$c/status" 2>/dev/null)" = connected ]; then
          printf '%s\n' "''${c##*/}"
          return 0
        fi
      done
      return 1
    }

    # Starts optimistic so a boot with the display already up logs nothing.
    was_connected=1

    while true; do
      if name=$(connected); then
        if [ "$was_connected" = 0 ]; then
          echo "display attached on $name"
          "$UDEVADM" trigger --action=change --subsystem-match=drm || true
        fi
        was_connected=1
        sleep 5
        continue
      fi

      if [ "$was_connected" = 1 ]; then
        echo "no display attached, forcing re-probe"
      fi
      was_connected=0

      # Reading status is cached and free; only this write touches the link, and it can
      # only run while nothing is attached, so a live session is never disturbed.
      for c in $(connectors); do
        echo detect > "$c/status" 2>/dev/null || true
      done
      sleep 3
    done
  '';
in
{
  systemd.services.dp-hotplug-rescan = {
    description = "Force DisplayPort re-detection while no display is attached";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${rescan}";
      Restart = "always";
      RestartSec = 2;
      StandardOutput = "journal";
      StandardError = "journal";
    };
  };
}
