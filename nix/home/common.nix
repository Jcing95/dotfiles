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
    LANG = "en_US.UTF-8";
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
          git worktree add "$dir_name" "$branch_name" || return 1
        elif git show-ref --verify --quiet "refs/remotes/origin/$branch_name"; then
          echo "Checking out remote branch 'origin/$branch_name' into './$dir_name'..."
          git worktree add -b "$branch_name" "$dir_name" "origin/$branch_name" || return 1
        else
          echo "Creating entirely new branch '$branch_name' into './$dir_name'..."
          git worktree add -b "$branch_name" "$dir_name" || return 1
        fi

        cd "$dir_name"
      }

      grm() {
        local force=""
        local -a rest
        local a
        for a in "$@"; do
          case "$a" in
            -f|--force) force="--force" ;;
            -*)
              echo "grm: unknown option '$a'" >&2
              return 1
              ;;
            *) rest+=("$a") ;;
          esac
        done

        if (( ''${#rest} != 1 )); then
          echo "Error: Please provide exactly one worktree."
          echo "Usage: grm [-f|--force] <worktree>"
          return 1
        fi

        if ! git rev-parse --git-dir >/dev/null 2>&1; then
          echo "grm: not inside a git repository" >&2
          return 1
        fi

        # Resolve the target against the worktree list, so either a bare
        # directory name ('feature-x') or a path ('../feature-x') works.
        local target="''${rest[1]}"
        local main_wt="" path="" branch="" found_path="" found_branch=""
        local line
        while IFS= read -r line; do
          case "$line" in
            worktree\ *)
              path="''${line#worktree }"
              [[ -z "$main_wt" ]] && main_wt="$path"
              branch=""
              ;;
            branch\ refs/heads/*) branch="''${line#branch refs/heads/}" ;;
            "")
              if [[ "$path" != "$main_wt" ]] &&
                 [[ "''${path:t}" == "$target" || "''${path:A}" == "''${target:A}" ]]; then
                found_path="$path"
                found_branch="$branch"
              fi
              ;;
          esac
        done < <(git worktree list --porcelain; echo)

        if [[ -z "$found_path" ]]; then
          echo "grm: no linked worktree matching '$target'" >&2
          echo "Existing worktrees:" >&2
          git worktree list >&2
          return 1
        fi

        # Step out to the main worktree first if we're standing inside the one
        # being removed, otherwise we'd be left in a deleted directory. Both
        # sides go through :A so a symlinked path still matches.
        local found_real="''${found_path:A}"
        if [[ "''${PWD:A}" == "$found_real" || "''${PWD:A}" == "$found_real"/* ]]; then
          cd "$main_wt" || return 1
        fi

        echo "Removing worktree '$found_path'..."
        if ! git worktree remove $force "$found_path"; then
          if [[ -z "$force" ]]; then
            echo "hint: re-run as: grm -f $target" >&2
          fi
          return 1
        fi

        # Clean up the branch only when git considers it safe to.
        if [[ -n "$found_branch" ]]; then
          local out
          if out=$(git branch -d "$found_branch" 2>&1); then
            echo "$out"
          else
            echo "$out" >&2
            echo "  delete anyway with: git branch -D $found_branch" >&2
          fi
        fi
      }

      # Complete grm with the basenames of the repo's linked worktrees.
      _grm() {
        if [[ "$words[CURRENT]" == -* ]]; then
          compadd -- -f --force
          return
        fi

        local -a names
        local line
        local n=0
        while IFS= read -r line; do
          [[ "$line" == worktree\ * ]] || continue
          (( ++n > 1 )) && names+=("''${''${line#worktree }:t}")
        done < <(git worktree list --porcelain 2>/dev/null)

        compadd -- $names
      }
      compdef _grm grm

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
    fileWidget.options = [
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

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      line-numbers = true;
      side-by-side = true;
    };
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

      # Whole-PR views: diff against the merge base with the upstream default
      # branch rather than HEAD, so all commits on the branch show up at once
      # and commits landed on main after branching stay out of the diff.
      # Each takes an optional base override, e.g. `git pr origin/release`.
      # These go through git diff/log, so delta renders them.
      alias =
        let
          resolveBase = "b=\"$1\"; [ -n \"$b\" ] || b=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null) || b=origin/main;";
        in
        {
          pr = "!f() { ${resolveBase} git diff \"$b...HEAD\"; }; f";
          prstat = "!f() { ${resolveBase} git diff --stat \"$b...HEAD\"; }; f";
          prfiles = "!f() { ${resolveBase} git diff --name-status \"$b...HEAD\"; }; f";
          prlog = "!f() { ${resolveBase} git log --oneline --no-merges \"$b..HEAD\"; }; f";
        };
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
