# Shared Home Manager configuration for all hosts
{ username, email, ... }:

{
  home.sessionVariables = {
    DOTFILES = "$HOME/dotfiles";
    EDITOR = "nvim";
  };

  programs.starship.enable = true;

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    autosuggestion.enable = true;

    history = {
      size = 10000;
      save = 10000;
      path = "$HOME/.zsh_history";
      ignoreDups = true;
      ignoreAllDups = true;
      share = true;
    };

    shellAliases = {
      ll = "ls -la";
      la = "ls -la";
      ws = "cd ~/workspace/";
      ":q" = "exit";
      q = "exit";
      cc = "clear && clear";
      src = "source ~/.zshrc";
      update = "nix flake update --flake $DOTFILES/nix";
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.gh = {
    enable = true;
    settings.git_protocol = "ssh";
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = username;
        inherit email;
      };
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      pull.rebase = true;
    };
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = [
      "--cmd"
      "cd"
    ];
  };
}
