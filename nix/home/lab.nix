# Home Manager configuration for lab
{ config, pkgs, lib, ... }:

let
  dotfiles = "${config.home.homeDirectory}/dotfiles";

  # Opens or reuses a workspace per job and either starts a coding agent in it or runs
  # a plain command. Shared by every timer below so a new job is four lines in `jobs`.
  #
  # Every herdr CLI call exits 0 even when it fails, so each response has to be
  # inspected for `.error` instead of relying on the exit status.
  herdr-job = pkgs.writeShellApplication {
    name = "herdr-job";
    runtimeInputs = [ pkgs.herdr pkgs.jq ];
    text = ''
      label=$1; cwd=$2; mode=$3; shift 3

      existing=$(herdr workspace list \
        | jq -r --arg l "$label" \
            '[.result.workspaces[]? | select(.label == $l) | .workspace_id][0] // empty')

      if [ -n "$existing" ]; then
        if [ "$mode" = agent ]; then
          # A live agent may still be mid-task or waiting on a question. A second one on
          # the same checkout would fight it over the worktree.
          echo "workspace $label already open; skipping" >&2
          exit 0
        fi
        # Plain commands reuse the pane, so the job keeps one stable workspace to open
        # from the phone. Creating a new one each time would stack them up, and skipping
        # would mean the job never runs again once the first workspace is left open.
        pane=$(herdr pane list --workspace "$existing" | jq -r '.result.panes[0].pane_id')
      else
        created=$(herdr workspace create --cwd "$cwd" --label "$label" --no-focus)
        if printf '%s' "$created" | jq -e '.error' >/dev/null; then
          printf '%s\n' "$created" | jq -r '"workspace create failed: " + .error.code' >&2
          exit 1
        fi
        pane=$(printf '%s' "$created" | jq -r '.result.root_pane.pane_id')
      fi

      if [ "$mode" = run ]; then
        herdr pane run "$pane" "$*"
        exit 0
      fi

      # `agent start` answers agent_not_ready when the agent comes up blocked, which
      # Claude's folder-trust prompt does on a directory it has not seen. The process is
      # live either way, so ignore that and let the wait decide.
      herdr agent start "$label" --kind claude --pane "$pane" \
        -- --dangerously-skip-permissions >/dev/null

      # Prompting a blocked agent would type into whatever dialog is holding it, so only
      # send the prompt once it is accepting input. Still blocked after two minutes means
      # a human has to look at it, which is what opening the pane from the phone is for.
      settled=$(herdr agent wait "$label" --until idle --until "done" --timeout 120000)
      if printf '%s' "$settled" | jq -e '.error' >/dev/null; then
        echo "agent $label never reached idle; left blocked for a human" >&2
        exit 0
      fi
      herdr agent prompt "$label" "$*" >/dev/null
    '';
  };

  # schedule is a systemd OnCalendar expression; mode is agent or run; arg is the
  # agent's prompt or the shell command.
  jobs = {
    flake-update = {
      schedule = "Mon 09:00";
      cwd = dotfiles;
      mode = "agent";
      # One line on purpose: this ends up verbatim in a systemd ExecStart, and unit
      # file values cannot span lines.
      arg = "Run `nix flake update` in nix/, then `nixos-rebuild build --flake nix/#lab` to check the result builds. Summarise what moved and anything that broke. Do not switch and do not commit.";
    };

    k3s-health = {
      schedule = "daily";
      cwd = config.home.homeDirectory;
      mode = "run";
      # Panes run an interactive zsh, where grep is aliased to ripgrep and -E means
      # --encoding. Let kubectl filter instead of piping through text tools.
      arg = "kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded";
    };
  };

  jobServices = lib.mapAttrs' (name: job:
    lib.nameValuePair "herdr-job-${name}" {
      Unit = {
        Description = "herdr job: ${name}";
        Requires = [ "herdr.service" ];
        After = [ "herdr.service" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${herdr-job}/bin/herdr-job ${
          lib.escapeShellArgs [ name job.cwd job.mode job.arg ]
        }";
      };
    }) jobs;

  jobTimers = lib.mapAttrs' (name: job:
    lib.nameValuePair "herdr-job-${name}" {
      Unit.Description = "herdr job schedule: ${name}";
      Timer = {
        OnCalendar = job.schedule;
        # Catch up after the box was down rather than silently skipping a week.
        Persistent = true;
        RandomizedDelaySec = 300;
      };
      Install.WantedBy = [ "timers.target" ];
    }) jobs;
in
{
  imports = [
    ./linux.nix
  ];

  programs.zsh.shellAliases = {
    tv-on = "sudo systemctl start greetd";
    tv-off = "sudo systemctl stop greetd";
  };

  home.sessionVariables.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";

  # moshi-hook installs itself here; see modules/herdr.nix for why it is not in nix.
  home.sessionPath = [ "$HOME/.local/bin" ];

  home.file.".config/hypr/host.lua".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/hypr/lab.lua";

  home.packages = with pkgs; [
    ssh-to-age
    sops
    herdr-job
  ];

  home.pointerCursor.size = 24;

  # Warn rather than fail: a missing hook costs phone approvals, not a working session.
  home.activation.moshiHookPresent = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -x "$HOME/.local/bin/moshi-hook" ]; then
      warnEcho "moshi-hook missing: no phone approvals. See nix/modules/herdr.nix."
    fi
  '';

  # Adaptive PowerMizer only ramps in response to X11 rendering notifications, so
  # under Wayland the GTX 980 stays pinned at its minimum 135 MHz / 324 MHz clocks
  # and the desktop drops frames while every utilisation counter reads idle.
  #
  # Mode 1 lifts it to P0, but the driver drops the override a few seconds after
  # the nvidia-settings client exits, hence the re-apply loop instead of a
  # one-shot. `nvidia-smi -lgc` would be the clean way to pin clocks; Maxwell
  # predates locked-clock support and reports it unsupported.
  #
  # DISPLAY must be set or nvidia-settings aborts with "control display is
  # undefined", even though it reaches the driver directly and tolerates the
  # display not actually existing (which is what covers the Xwayland startup race).
  #
  # No ExecStop: the override lapses by itself once re-application stops, so the
  # card falls back to P8 when the session ends.
  systemd.user.services = {
    nvidia-powermizer = {
      Unit = {
        Description = "NVIDIA PowerMizer: maximum performance while a graphical session is up";
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        Environment = "DISPLAY=:0";
        ExecStart = pkgs.writeShellScript "nvidia-powermizer" ''
          while :; do
            /run/current-system/sw/bin/nvidia-settings -a '[gpu:0]/GPUPowerMizerMode=1' >/dev/null 2>&1 || true
            sleep 4
          done
        '';
        Restart = "always";
        RestartSec = 5;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    # Bare `herdr server` is the headless mode; `herdr` alone would launch the TUI.
    # Deliberately not tied to graphical-session.target like the unit above: the phone
    # and the timers need this up on a headless boot, which is what linger buys
    # (modules/herdr.nix).
    #
    # Never `herdr update` here. The binary is nix-managed, and live handoff under a
    # user unit is an upstream break (herdr #4972) that kills panes or orphans the new
    # server. Updates come from `nix flake update` plus a rebuild, which restarts this
    # unit: layout and cwds survive, pane processes do not.
    herdr = {
      Unit.Description = "herdr agent session server";
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.herdr}/bin/herdr server";
        ExecStop = "${pkgs.herdr}/bin/herdr server stop";
        Restart = "on-failure";
        RestartSec = 5;
        # Panes inherit this unit's environment, not a login shell's. Interactive panes
        # get PATH repaired by /etc/zshenv, but `herdr pane run` execs without a shell.
        Environment = [
          "PATH=/etc/profiles/per-user/${config.home.username}/bin:/run/current-system/sw/bin:${config.home.homeDirectory}/.local/bin"
          "KUBECONFIG=/etc/rancher/k3s/k3s.yaml"
        ];
      };
      Install.WantedBy = [ "default.target" ];
    };
  } // jobServices;

  systemd.user.timers = jobTimers;
}
