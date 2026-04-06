# macbook-jcing host configuration
{ pkgs, username, ... }:

{
  imports = [
    ../../modules/darwin.nix
  ];

  # Hostname
  networking.hostName = "macbook-jcing";

  system.primaryUser = username;

  # User
  users.users.${username} = {
    home = "/Users/${username}";
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

    casks = [
      "raycast"
      "1password"
      "1password-cli"
      "dbeaver-community"
      "font-fira-code-nerd-font"
      "postman"
      "visual-studio-code"
      "wezterm"
    ];
  };
}
