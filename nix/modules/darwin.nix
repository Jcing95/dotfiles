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
    fzf
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

  environment.variables.EDITOR = "nvim";

  # Shell configuration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableSyntaxHighlighting = true;

    # PATH and global exports (runs for all shells including non-interactive)
    shellInit = ''
      export DOTFILES="$HOME/dotfiles"

      export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"
      export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
      export PATH="''${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

      export KUBE_EDITOR="nvim"

      if [ -f "$HOME/.deno/env" ]; then
        . "$HOME/.deno/env"
      fi
    '';

    interactiveShellInit = ''
      autoload -U up-line-or-beginning-search
      autoload -U down-line-or-beginning-search
      zle -N up-line-or-beginning-search
      zle -N down-line-or-beginning-search
      bindkey "^[[A" up-line-or-beginning-search
      bindkey "^[[B" down-line-or-beginning-search

      alias ll="ls -la"
      alias la="ls -la"
      alias k=kubectl
      alias cs='cd ~/workspace/codesphere-monorepo'
      alias csp='cd ~/workspace/codesphere-monorepo/packages'
      alias ws='cd ~/workspace/'
      alias wsp='cd ~/workspace/private/'
      alias yib='yarn install && yarn build'
      alias src='source ~/.zshrc'
      alias rebuild="sudo darwin-rebuild switch --flake $DOTFILES/nix#macbook-jcing"
      alias config="cd $DOTFILES && nvim"
      alias ":q"="exit"
      alias "q"="exit"
      alias cc='clear && clear'
    '';
  };

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
