# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      /etc/nixos/hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader = {
    efi.canTouchEfiVariables = true;
    timeout = 3;
    systemd-boot = {
      enable = true;
      configurationLimit = 3;
      extraInstallCommands = ''
        ${pkgs.gnused}/bin/sed -i 's/^default .*/default auto-windows/' /boot/loader/loader.conf
      '';
    };
  };
  networking = {
    hostName = "nixos"; # Define your hostname.
    nameservers = [ "1.1.1.1" "1.0.0.1" "2606:4700:4700::1111" "2606:4700:4700::1001" ];
    networkmanager.enable = true;
    networkmanager.dns = "default";
  };

  
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
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

  # Configure console keymap
  console.keyMap = "de";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.jcing = {
    isNormalUser = true;
    description = "Jcing";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      brave
      telegram-desktop
      discord
      spotify
      prismlauncher
    ];
  };

  # Allow unfree packages
  nixpkgs.config = {
    allowUnfree = true;
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    WLR_NO_HARDWARE_CURSORS = "1";
  };
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
    dunst
    neovim
    lazygit
    tree-sitter
    gcc
    pulseaudioFull
    curl
    fzf
    ripgrep
    fd
    wezterm
    dmenu
    gnome-keyring
    polkit
    rofi
    waybar
    unzip
    unrar
    wl-clipboard
    hyprpaper
    hyprshot
    goxlr-utility
    nextcloud-client
    pwvucontrol
    networkmanagerapplet
    nwg-displays
    nwg-look
    wlsunset
    psmisc
    hypridle
    nordzy-cursor-theme
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
  ];

  programs = {
    hyprland = {
      enable = true;
    };
    starship.enable = true;
    dconf.enable = true;
    thunar.enable = true; 
    _1password.enable = true;
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = [
        "jcing"
      ];
    };
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;
      shellAliases = {
        ll = "ls -la";
	      os-rebuild = "sudo nixos-rebuild switch";
        os-gc = "sudo nix-env --delete-generations old && nix-collect-garbage -d";
      };
      histSize = 10000;
      histFile = "$HOME/.zsh_history";
      setOptions = [
        "HIST_IGNORE_ALL_DUPS"
      ];
    };
    steam = {
        enable = true;
    };
  };

  users.defaultUserShell = pkgs.zsh;
  boot.kernelModules = [ "amdgpu" ];
  boot.kernelPackages = pkgs.linuxPackages_latest;
  
  services = {
    xserver = {
      enable = true;
      videoDrivers = ["nvidia"];
    };
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = false;
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
    };
    gvfs.enable = true;
    gnome.gnome-keyring.enable = true;
    blueman.enable = true;
  };

  systemd = {
    user.services.polkit-gnome-authentication-agent-1 = {
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
    user.services.goxlr-utility = {
      description = "GoXLR Utility";
      wantedBy = [ "default.target" ];
      after = [ "pipewire.service" ];
      serviceConfig = {
        ExecStart = "${pkgs.goxlr-utility}/bin/goxlr-utility";
        Restart = "always";
        RestartSec = "5s";
      };
    };
    user.services.goxlr-set-default = {
      description = "Set GoXLR System as default sink";
      after = [ 
          "pipewire-pulse.service"
          "goxlr-utility.service"
      ];
      requires = [ "goxlr-utility.service" ];
      wantedBy = [ "pipewire-pulse.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.pulseaudio}/bin/pactl set-default-sink alsa_output.usb-TC-Helicon_GoXLRMini-00.HiFi__Speaker__sink";
        RemainAfterExit = true;
      };
    };
  };

  security = {
    rtkit.enable = true;
    polkit.enable = true;
  };

  hardware = {
    graphics.enable = true;
    bluetooth.enable = true;
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      
      prime = {
          offload.enable = true;
          offload.enableOffloadCmd = true;
          intelBusId = "PCI:00:02:0";
          nvidiaBusId = "PCI:01:00:0";
        };

      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };
  
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}
