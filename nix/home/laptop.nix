# Home Manager configuration for laptop
{ config, pkgs, lib, ... }:

let
  dotfiles = "${config.home.homeDirectory}/dotfiles";
in
{
  imports = [
    ./linux.nix
  ];

  home.file.".config/hypr/host.lua".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/hypr/laptop.lua";

  home.packages = with pkgs; [
    brave
    spotify
    claude-code
  ];

  home.pointerCursor.size = 24;

  # hypridle: dim/lock/suspend on idle. Config is written directly (not via
  # services.hypridle) because the HM unit is gated on graphical-session.target,
  # which our greetd/Hyprland launch path doesn't activate. hypridle is started
  # from hypr/autostart.lua instead.
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

    # 10min: lock screen
    listener {
      timeout = 600
      on-timeout = loginctl lock-session
    }

    # 15min: suspend
    listener {
      timeout = 900
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
