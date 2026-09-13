# macbook-jcing host configuration
{ pkgs, username, ... }:

{
  imports = [
    ../../modules/darwin.nix
  ];

  networking.hostName = "macbook-jcing";

  system.primaryUser = username;

  users.users.${username} = {
    home = "/Users/${username}";
    shell = pkgs.zsh;
  };

  homebrew = {
    enable = true;

    casks = [
      "raycast"
      "1password"
      "1password-cli"
      "dbeaver-community"
      "font-fira-code-nerd-font"
      "gpg-suite"
      "postman"
      "visual-studio-code"
      "wezterm"
    ];
  };
}
