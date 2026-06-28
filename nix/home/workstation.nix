# Home Manager configuration for workstation
{ config, pkgs, lib, ... }:

let
  dotfiles = "${config.home.homeDirectory}/dotfiles";
in
{
  imports = [
    ./linux.nix
  ];

  home.file.".config/hypr/host.lua".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/hypr/workstation.lua";

  # Nextcloud must own its own config file: it persists account/sync state and
  # saves via an atomic rename, so the target has to be a real, writable file —
  # not a (read-only) nix-store symlink or an out-of-store symlink (the rename
  # would clobber the link). We only seed the experimental-options flag once,
  # then leave the file for Nextcloud to manage.
  home.activation.nextcloudCfg = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    cfg="$HOME/.config/Nextcloud/nextcloud.cfg"
    $DRY_RUN_CMD mkdir -p "$(dirname "$cfg")"

    # Drop a read-only store symlink left by a previous generation.
    if [ -L "$cfg" ]; then
      $DRY_RUN_CMD rm -f "$cfg"
    fi

    if [ ! -e "$cfg" ]; then
      $DRY_RUN_CMD tee "$cfg" >/dev/null <<'EOF'
[General]
showExperimentalOptions=true
EOF
      $DRY_RUN_CMD chmod 600 "$cfg"
    elif ! ${pkgs.gnugrep}/bin/grep -q '^showExperimentalOptions' "$cfg"; then
      # Enable the experiment without disturbing Nextcloud's own settings.
      $DRY_RUN_CMD ${pkgs.gnused}/bin/sed -i '0,/^\[General\]/s//[General]\nshowExperimentalOptions=true/' "$cfg"
    fi
  '';

  home.packages = with pkgs; [
    brave
    telegram-desktop
    discord
    spotify
    prismlauncher
    nextcloud-client
    claude-code
    bolt-launcher
    runelite
    devenv
    hueadm
    heroic
    lutris
    bottles
    umu-launcher
    cameractrls-gtk4
  ];

  home.pointerCursor.size = 36;

  # Config is written directly (not via services.hypridle) because the HM unit
  # is gated on graphical-session.target, which our greetd/Hyprland launch path
  # doesn't activate. hypridle is started from hypr/autostart.lua instead.
  home.file.".config/hypr/hypridle.conf".text = ''
    general {
      # Clear the ssh-agent on every lock (idle, sleep, manual all route here via
      # loginctl lock-session) so the key passphrase must be re-entered after unlock.
      lock_cmd = SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/gcr/ssh ssh-add -D 2>/dev/null; pidof hyprlock || hyprlock
      before_sleep_cmd = loginctl lock-session
      after_sleep_cmd = hyprctl dispatch dpms on
    }

    # 2.5min: dim display backlight (avoid 0 on OLED)
    listener {
      timeout = 150
      on-timeout = brightnessctl -s set 10
      on-resume = brightnessctl -r
    }

    # 2.5min: turn off keyboard backlight
    listener {
      timeout = 150
      on-timeout = brightnessctl -sd rgb:kbd_backlight set 0
      on-resume = brightnessctl -rd rgb:kbd_backlight
    }

    # 5.5min: DPMS off
    listener {
      timeout = 330
      on-timeout = hyprctl dispatch dpms off
      on-resume = hyprctl dispatch dpms on && brightnessctl -r
    }

    # 30min: lock screen
    listener {
      timeout = 1800
      on-timeout = loginctl lock-session
    }

    # 60min: suspend
    listener {
      timeout = 3600
      on-timeout = systemctl suspend
    }
  '';

  systemd.user.services.wlsunset = {
    Unit = {
      Description = "wlsunset day/night gamma adjustment";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.wlsunset}/bin/wlsunset -l 49.0 -L 8.4";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
