# Shared Home Manager configuration for all hosts
{ config, pkgs, username, email, ... }:

let
  dotfiles = "${config.home.homeDirectory}/dotfiles";
in

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
    obsidian
  ];

  home.sessionVariables = {
    DOTFILES = "$HOME/dotfiles";
    EDITOR = "nvim";
    MANPAGER = "bat -l man -p";
  };

  programs.starship.enable = true;

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    autosuggestion.enable = true;

    history = {
      size = 100000;
      save = 100000;
      path = "$HOME/.zsh_history";
      ignoreDups = true;
      ignoreAllDups = true;
      share = true;
    };

    plugins = [
      {
        name = "zsh-history-substring-search";
        src = pkgs.zsh-history-substring-search;
        file = "share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh";
      }
    ];

    initContent = ''
      any-nix-shell zsh --info-right | source /dev/stdin

      # History and shell behaviour
      setopt HIST_IGNORE_SPACE HIST_EXPIRE_DUPS_FIRST HIST_FIND_NO_DUPS APPEND_HISTORY
      setopt AUTOCD NOBEEP NUMERIC_GLOB_SORT

      # Completion styling
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
      compdef eza=ls

      # Keybindings
      bindkey '^[[A' history-substring-search-up
      bindkey '^[[B' history-substring-search-down
      bindkey '^[[1;5C' forward-word
      bindkey '^[[1;5D' backward-word

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

      # zoxide (kept last, as recommended). Skipped under Claude Code, whose
      # sandboxed shell breaks on the `--cmd cd` override.
      if [[ -z "$CLAUDECODE" ]]; then
        eval "$(${config.programs.zoxide.package}/bin/zoxide init zsh --cmd cd)"
      fi
    '';

    shellAliases = {
      ls = "eza --icons";
      ll = "eza -lah --icons --git";
      la = "eza -lah --icons --git";
      tree = "eza --tree --icons";
      ws = "cd ~/workspace/";
      ":q" = "exit";
      q = "exit";
      cc = "clear && clear";
      src = "source ~/.zshrc";
      update = "nix flake update --flake $DOTFILES/nix";
      k = "kubectl";
      vim = "nvim";
      grep = "rg --color=auto";
      "-" = "cd -";
      glog = "PAGER='less -F -X' git log";
      gadog = "PAGER='less -F -X' git log --all --decorate --oneline --graph";
    };
  };

  programs.fd.enable = true;

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f --hidden --strip-cwd-prefix";
    defaultOptions = [
      "--height=60%"
      "--layout=reverse"
      "--border=rounded"
    ];
    fileWidgetOptions = [
      "--preview 'bat --color=always --style=plain,numbers --line-range=:500 {}'"
    ];
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
    delta = {
      enable = true;
      options = {
        navigate = true;
        line-numbers = true;
        side-by-side = true;
      };
    };
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
    # Integration is added manually (guarded) in programs.zsh.initContent below.
    # Under Claude Code the `--cmd cd` override breaks the sandboxed shell:
    # zoxide can't write its DB (blocked path -> error spam on every cd) and
    # `cd` silently fuzzy-jumps to the wrong directory instead of erroring.
    enableZshIntegration = false;
  };

  # OpenCode config (file-level symlinks; runtime files like node_modules stay untracked in ~/.config/opencode)
  home.file.".config/opencode/opencode.jsonc".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/opencode/opencode.jsonc";
  home.file.".config/opencode/RULES.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/opencode/RULES.md";
  home.file.".config/opencode/skills".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/opencode/skills";

  # Claude Code config (file-level symlinks; runtime state in ~/.claude stays untracked)
  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/claude/settings.json";
  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/claude/CLAUDE.md";
  home.file.".claude/skills".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/claude/skills";
}
