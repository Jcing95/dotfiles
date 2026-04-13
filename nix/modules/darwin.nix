# Shared nix-darwin core settings
{ pkgs, username, ... }:

{
  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" username ];
    extra-trusted-substituters = [ "https://cache.lix.systems" ];
    extra-trusted-public-keys = [ "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o=" ];
  };

  nix.gc = {
    automatic = true;
    interval = { Weekday = 7; Hour = 3; Minute = 0; };
    options = "--delete-older-than 30d";
  };
  nix.optimise.automatic = true;

  environment.systemPackages = with pkgs; [
    git
    git-lfs
    lazygit
    neovim
    tmux

    colima
    docker-client
    docker-compose
    k9s
    kubectl
    kubernetes-helm
    kubelogin-oidc

    curl
    ripgrep
    fd
    tree-sitter
    unzip
  ];

  homebrew = {
    enable = true;

    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };

    casks = [
      "raycast"
      "1password"
      "1password-cli"
      "dbeaver-community"
      "font-hack-nerd-font"
      "postman"
      "visual-studio-code"
      "wezterm"
      "cloudflare-warp"
    ];
  };

  # ZSH as system shell (user-level config is in Home Manager)
  programs.zsh.enable = true;

  system.defaults = {
    dock = {
      autohide = true;
      show-recents = false;
      mru-spaces = false;
    };

    finder = {
      AppleShowAllExtensions = true;
      FXPreferredViewStyle = "clmv";
    };

    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      AppleInterfaceStyle = "Dark";
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
      _HIHideMenuBar = true;
    };

    CustomUserPreferences = {
      "com.apple.symbolichotkeys" = {
        AppleSymbolicHotKeys = {
          # Disable "Show Spotlight search" (Cmd+Space)
          "64" = { enabled = false; };
          # Disable "Show Finder search window" (Opt+Cmd+Space)
          "65" = { enabled = false; };
          # Area screenshot to clipboard → Cmd+Shift+S
          "31" = {
            enabled = true;
            value = {
              parameters = [ 115 1 1179648 ];
              type = "standard";
            };
          };
          # Screenshot and recording options → Cmd+Shift+V
          "184" = {
            enabled = true;
            value = {
              parameters = [ 118 9 1179648 ];
              type = "standard";
            };
          };
        };
      };
    };

    trackpad = {
      Clicking = true;
      TrackpadRightClick = true;
    };
  };

  # macOS services
  services.aerospace = {
    enable = true;
    settings = builtins.fromTOML (builtins.readFile ../../darwin/aerospace.toml);
  };

  services.jankyborders = {
    enable = true;
    width = 6.0;
    style = "round";
    hidpi = true;
    active_color = "0xF016701c";
    inactive_color = "0x80104f14";
    background_color = "0x302c2e34";
  };

  services.sketchybar = {
    enable = true;
    config = ''
      #!/usr/bin/env bash
      source "$HOME/.config/sketchybar/sketchybarrc"
    '';
  };

  system.activationScripts.postActivation.text = ''
    sudo -u ${username} ${pkgs.sketchybar}/bin/sketchybar --reload 2>/dev/null || true
  '';

  # Host platform
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Used for backwards compatibility
  system.stateVersion = 6;
}
