# Shared Home Manager configuration for all hosts
{ pkgs, username, email, ... }:

{
  home.packages = with pkgs; [
    any-nix-shell
    affine
    btop
    dust
    tldr
    opencode
    claude-code
    codex
    zmk-studio
  ];

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

    initContent = ''
      any-nix-shell zsh --info-right | source /dev/stdin

      gwt() {
        if [[ -z "$1" ]]; then
          echo "Error: Please provide a branch name."
          echo "Usage: gwt <branch-name>"
          return 1
        fi

        local branch_name="$1"
        local dir_name="''${branch_name##*/}"

        if git show-ref --verify --quiet "refs/heads/$branch_name"; then
          echo "Checking out local branch '$branch_name' into './$dir_name'..."
          git worktree add "$dir_name" "$branch_name"
        elif git show-ref --verify --quiet "refs/remotes/origin/$branch_name"; then
          echo "Checking out remote branch 'origin/$branch_name' into './$dir_name'..."
          git worktree add -b "$branch_name" "$dir_name" "origin/$branch_name"
        else
          echo "Creating entirely new branch '$branch_name' into './$dir_name'..."
          git worktree add -b "$branch_name" "$dir_name"
        fi
      }
    '';

    shellAliases = {
      ls = "eza --icons";
      ll = "eza -lah --icons --git";
      la = "eza -lah --icons --git";
      ws = "cd ~/workspace/";
      ":q" = "exit";
      q = "exit";
      cc = "clear && clear";
      src = "source ~/.zshrc";
      update = "nix flake update --flake $DOTFILES/nix";
      k = "kubectl";
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

  programs.bat.enable = true;

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.tmux = {
    enable = true;
    terminal = "tmux-256color";
    historyLimit = 10000;
    escapeTime = 0;
    mouse = true;
    keyMode = "vi";
    baseIndex = 1;
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
