# Home Manager configuration for macbook
{ config, pkgs, username, ... }:

let
  dotfiles = "${config.home.homeDirectory}/dotfiles";
in
{
  imports = [
    ./common.nix
  ];

  home.username = username;
  home.homeDirectory = "/Users/${username}";
  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    github-copilot-cli
    oms
    google-cloud-sdk
    cloudflared
  ];

  # Dotfile symlinks (out-of-store so changes are reflected immediately)
  home.file.".config/wezterm".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/wezterm";
  home.file.".config/nvim".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/lazyvim";
  home.file.".config/aerospace/aerospace.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/darwin/aerospace.toml";

  # Sketchybar config (out-of-store symlink so .lua edits take effect on --reload, no rebuild needed)
  home.file.".config/sketchybar".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/darwin/sketchybar";

  home.sessionPath = [
    "/opt/homebrew/opt/openjdk@21/bin"
    "/opt/homebrew/opt/openjdk/bin"
  ];

  home.sessionVariables = {
    KUBE_EDITOR = "nvim";
    CODESPHERE_DIRENV_AUTOSECRETS = "1";
  };

  programs.zsh.shellAliases = {
    cs = "cd ~/workspace/codesphere-monorepo";
    csp = "cd ~/workspace/codesphere-monorepo/packages";
    wsp = "cd ~/workspace/private/";
    yib = "yarn install && yarn build";
    rebuild = "sudo darwin-rebuild switch --flake $DOTFILES/nix#macbook-jcing";
    config = "cd $DOTFILES && nvim";
  };

  programs.zsh.initContent = ''
    # Krew PATH (needs runtime expansion of KREW_ROOT)
    export PATH="''${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

    # Deno environment
    if [ -f "$HOME/.deno/env" ]; then
      . "$HOME/.deno/env"
    fi
  '';

  programs.home-manager.enable = true;
}
