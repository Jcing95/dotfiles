# macbook-jcing host configuration
{ pkgs, ... }:

{
  imports = [
    ../../modules/darwin/core.nix
  ];

  # Hostname
  networking.hostName = "macbook-jcing";

  system.primaryUser = "jcing";
  # User
  users.users.jcing = {
    home = "/Users/jcing";
    shell = pkgs.zsh;
  };

  # Homebrew (managed declaratively by nix-darwin)
  homebrew = {
    enable = true;

    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };

    taps = [
      "felixkratz/formulae"
      "nikitabobko/tap"
    ];

    # Tap-only formulae that aren't in nixpkgs
    brews = [
      "borders"
    ];

    casks = [
      "1password"
      "1password-cli"
      "nikitabobko/tap/aerospace"
      "alt-tab"
      "dbeaver-community"
      "font-hack-nerd-font"
      "iterm2"
      "postman"
      "rectangle"
      "stats"
      "visual-studio-code"
      "wezterm"
    ];
  };
}
