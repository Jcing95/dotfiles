# Core system configuration shared by all hosts
{ config, pkgs, ... }:

{
  # Nix settings
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Bootloader base config
  boot.loader = {
    efi.canTouchEfiVariables = true;
    timeout = 3;
    systemd-boot = {
      enable = true;
      configurationLimit = 3;
    };
  };

  # Networking base
  networking = {
    nameservers = [ "1.1.1.1" "1.0.0.1" "2606:4700:4700::1111" "2606:4700:4700::1001" ];
    networkmanager.enable = true;
    networkmanager.dns = "default";
  };

  # Locale & timezone
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };
  console.keyMap = "de";

  # User account
  users.users.jcing = {
    isNormalUser = true;
    description = "Jcing";
    extraGroups = [ "networkmanager" "wheel" ];
  };
  users.defaultUserShell = pkgs.zsh;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Core system packages
  environment.systemPackages = with pkgs; [
    git
    neovim
    lazygit
    tree-sitter
    gcc
    curl
    fzf
    ripgrep
    fd
    unzip
    unrar
    psmisc
  ];

  # ZSH system-wide config
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      ll = "ls -la";
      os-rebuild = "sudo nixos-rebuild switch --flake ~/dotfiles";
      os-gc = "sudo nix-env --delete-generations old && nix-collect-garbage -d";
    };
    histSize = 10000;
    histFile = "$HOME/.zsh_history";
    setOptions = [ "HIST_IGNORE_ALL_DUPS" ];
  };

  # Common programs
  programs = {
    starship.enable = true;
    dconf.enable = true;
    thunar.enable = true;
    _1password.enable = true;
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "jcing" ];
    };
  };

  # Security
  security = {
    rtkit.enable = true;
    polkit.enable = true;
    pam.services.hyprlock = {};
  };

  # Polkit authentication agent
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome-authentication-agent-1";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  # Base services
  services = {
    gvfs.enable = true;
    gnome.gnome-keyring.enable = true;
  };

  system.stateVersion = "25.05";
}
