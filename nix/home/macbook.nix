# Home Manager configuration for macbook
{ pkgs, username, omsSrc, ... }:

let
  oms = pkgs.callPackage ../pkgs/oms.nix { src = omsSrc; };

  sketchybarConfig = pkgs.stdenvNoCC.mkDerivation {
    name = "sketchybar-config";
    src = ../../darwin/sketchybar;
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out
      cp -r $src/* $out/
      find $out -name '*.sh' -exec chmod +x {} \;
      chmod +x $out/sketchybarrc
    '';
  };
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

  # Dotfile symlinks
  home.file.".config/wezterm".source = ../../wezterm;
  home.file.".config/nvim".source = ../../lazyvim;

  # Sketchybar config (deployed with executable permissions)
  home.file.".config/sketchybar".source = sketchybarConfig;

  home.sessionPath = [
    "/opt/homebrew/opt/openjdk@21/bin"
    "/opt/homebrew/opt/openjdk/bin"
  ];

  home.sessionVariables = {
    KUBE_EDITOR = "nvim";
  };

  programs.zsh.shellAliases = {
    k = "kubectl";
    cs = "cd ~/workspace/codesphere-monorepo";
    csp = "cd ~/workspace/codesphere-monorepo/packages";
    wsp = "cd ~/workspace/private/";
    yib = "yarn install && yarn build";
    rebuild = "sudo darwin-rebuild switch --flake $DOTFILES/nix#macbook-jcing";
    config = "cd $DOTFILES && nvim";
  };

  programs.zsh.initContent = ''
    # Up/down arrow: prefix-based history search
    autoload -U up-line-or-beginning-search
    autoload -U down-line-or-beginning-search
    zle -N up-line-or-beginning-search
    zle -N down-line-or-beginning-search
    bindkey "^[[A" up-line-or-beginning-search
    bindkey "^[[B" down-line-or-beginning-search

    # Krew PATH (needs runtime expansion of KREW_ROOT)
    export PATH="''${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

    # Deno environment
    if [ -f "$HOME/.deno/env" ]; then
      . "$HOME/.deno/env"
    fi
  '';

  programs.starship.enable = true;
  programs.home-manager.enable = true;
}
