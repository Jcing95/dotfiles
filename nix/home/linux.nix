# Shared Home Manager configuration for Linux desktops
{ config, pkgs, ... }:

let
  dotfiles = "${config.home.homeDirectory}/dotfiles";
in
{
  imports = [
    ./common.nix
  ];
 
  home.packages = with pkgs; [
    mgba
  ];
  home.stateVersion = "25.05";

  # Use the persistent gnome-keyring ssh-agent rather than wezterm's per-mux one,
  # so a key added in one terminal is reachable everywhere (incl. the lock script).
  home.sessionVariables.SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/gcr/ssh";

  programs.zsh.shellAliases = {
    rebuild = "sudo nixos-rebuild switch --flake $DOTFILES/nix#$(hostname)";
    os-gc = "sudo nix-env --delete-generations old && nix-collect-garbage -d";
    config = "nvim $DOTFILES";
    secrets = "sudo -E sops";
    k = "kubectl";
  };

  # Dotfile symlinks (out-of-store so changes are reflected immediately)
  home.file.".config/wezterm".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/wezterm";
  home.file.".config/nvim".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/lazyvim";
  home.file.".config/waybar".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/waybar";
  home.file.".config/hypr/hyprland.lua".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/hypr/hyprland.lua";
  home.file.".config/hypr/config".source       = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/hypr/config";
  home.file.".config/dunst".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/dunst";

  home.pointerCursor = {
    name = "Nordzy-cursors-white";
    package = pkgs.nordzy-cursor-theme;
    gtk.enable = true;
    x11.enable = true;
  };

  gtk = {
    enable = true;

    theme = {
      name = "Ayu-Dark";
      package = pkgs.ayu-theme-gtk;
    };

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };

    gtk4 = {
      theme = null;  # GTK4 apps use libadwaita, explicit theming not needed
      extraConfig.gtk-application-prefer-dark-theme = true;
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style.name = "adwaita-dark";
  };

  services.hyprpolkitagent.enable = true;

  # Dunst as a graphical-session systemd user unit (replaces autostart.lua entry).
  # Manual unit instead of services.dunst: the existing ~/.config/dunst/dunstrc is
  # symlinked out-of-store (line 36 above) and HM's dunst module would clobber it.
  systemd.user.services.dunst = {
    Unit = {
      Description = "Dunst notification daemon";
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "dbus";
      BusName = "org.freedesktop.Notifications";
      ExecStart = "${pkgs.dunst}/bin/dunst";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
