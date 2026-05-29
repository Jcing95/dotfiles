# Home Manager configuration for workstation
{ config, pkgs, ... }:

let
  dotfiles = "${config.home.homeDirectory}/dotfiles";
in
{
  imports = [
    ./linux.nix
  ];

  # Nextcloud needs a writable config file, not a nix store symlink
  home.file.".config/Nextcloud/nextcloud.cfg".text = builtins.readFile ../../nextcloud.cfg;
  home.file.".config/hypr/host.lua".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/hypr/workstation.lua";

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

  # Hypridle and wlsunset on workstation only — homelab is mostly headless and
  # must stay reachable, so we deliberately don't run an idle daemon there.
  # Config is written directly (not via services.hypridle) because the HM unit
  # is gated on graphical-session.target, which our greetd/Hyprland launch path
  # doesn't activate. hypridle is started from hypr/autostart.lua instead.
  home.file.".config/hypr/hypridle.conf".text = ''
    general {
      lock_cmd = pidof hyprlock || hyprlock
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

    # 5min: lock screen
    listener {
      timeout = 300
      on-timeout = loginctl lock-session
    }

    # 5.5min: DPMS off
    listener {
      timeout = 330
      on-timeout = hyprctl dispatch dpms off
      on-resume = hyprctl dispatch dpms on && brightnessctl -r
    }

    # 30min: suspend
    listener {
      timeout = 1800
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
