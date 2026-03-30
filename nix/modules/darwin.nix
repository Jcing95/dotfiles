# Shared nix-darwin core settings
{ pkgs, ... }:

{
  # Nix settings
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" "jcing" ];
    extra-trusted-substituters = [ "https://cache.lix.systems" ];
    extra-trusted-public-keys = [ "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o=" ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System packages (CLI tools)
  environment.systemPackages = with pkgs; [
    # Dev tools
    git
    git-lfs
    lazygit
    neovim
    tmux

    # Container & k8s
    colima
    docker-client
    docker-compose
    k9s
    kubectl
    kubernetes-helm
    kubelogin-oidc

    # macOS utilities
    aldente

    # CLI utilities
    curl
    fzf
    ripgrep
    fd
    tree-sitter
    gcc
    unzip
    home-manager
    starship
  ];

  # Default editor
  environment.variables.EDITOR = "nvim";

  # Shell configuration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableSyntaxHighlighting = true;

    interactiveShellInit = ''
      # Up/down arrow: history search by prefix
      autoload -U up-line-or-beginning-search
      autoload -U down-line-or-beginning-search
      zle -N up-line-or-beginning-search
      zle -N down-line-or-beginning-search
      bindkey "^[[A" up-line-or-beginning-search
      bindkey "^[[B" down-line-or-beginning-search
    '';
    
    shellInit = ''
      # PATH additions
      export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"
      export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
      export PATH="''${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
      export PATH="/Users/jcing/tailwindcss:$PATH"

      # Environment variables
      export KUBE_EDITOR="nvim"

      # Deno
      if [ -f "$HOME/.deno/env" ]; then
        . "$HOME/.deno/env"
      fi

      # Aliases
      alias ll="ls -la"
      alias la="ls -la"
      alias k=kubectl
      alias cs='cd ~/workspace/codesphere-monorepo'
      alias csp='cd ~/workspace/codesphere-monorepo/packages'
      alias ws='cd ~/workspace/'
      alias wsp='cd ~/workspace/private/'
      alias yib='yarn install && yarn build'
      alias src='source ~/.zshrc'
      alias rebuild="home-manager switch --flake $DOTFILES/nix#jcing@macbook-jcing"
      alias os-rebuild="sudo darwin-rebuild switch --flake $DOTFILES/nix#macbook-jcing"
      alias config="cd $DOTFILES && nvim"
      alias ":q"="exit"
      alias "q"="exit"
      alias cc='clear && clear'
    '';
  };

  # macOS system defaults
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
    };

    trackpad = {
      Clicking = true;
      TrackpadRightClick = true;
    };
  };

  # Host platform
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Used for backwards compatibility
  system.stateVersion = 6;
}
