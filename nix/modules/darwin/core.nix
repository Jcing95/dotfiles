# Shared nix-darwin core settings
{ pkgs, ... }:

{
  # Nix settings
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" "jcing" ];
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
      eval "$(starship init zsh)"
    '';
    
    shellInit = ''
      # Aliases
      alias ll="ls -la"
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
