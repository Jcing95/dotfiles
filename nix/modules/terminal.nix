# ZSH system-wide config (NixOS)
{ username, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "ls -la";
      rebuild = "sudo nixos-rebuild switch --flake $DOTFILES/nix#$(hostname)";
      os-gc = "sudo nix-env --delete-generations old && nix-collect-garbage -d";
      ws = "cd ~/workspace/";
      config = "nvim ~/workspace/dotfiles/";
      ":q" = "exit";
      q = "exit";
    };

    histSize = 10000;
    histFile = "$HOME/.zsh_history";
    setOptions = [ "HIST_IGNORE_ALL_DUPS" ];
  };
}
