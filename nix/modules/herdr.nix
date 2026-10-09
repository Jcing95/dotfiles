# herdr: the agent runtime for this box. Panes live in a background server so the
# phone and the workstation attach to one session instead of each getting their own.
# The server unit, the job wrapper and the timers are in home/lab.nix; this file holds
# the two system-level concerns plus the record of what nix does not manage.
#
# OUT-OF-BAND DEPENDENCY: moshi-hook is installed imperatively, not by nix. It is a
# prebuilt Go binary served from cdn.getmoshi.app with no nixpkgs entry, it self-updates,
# and it writes its own systemd user unit. Reproduce it on a fresh install with:
#
#   curl -fsSL https://getmoshi.app/install.sh | sh   # -> ~/.local/bin, symlinks `moshi`
#   moshi-hook pair --token <Moshi -> Settings -> Hooks>
#   moshi-hook service install
#
# The pairing token is per-device and cannot be checked in. Without it herdr still works
# and the phone still sees per-pane agent state; what is lost is approvals on the Live
# Activity and the watch. home/lab.nix warns on rebuild when the binary is missing.
#
# Also out of band, and only once per directory: Claude Code asks to trust a folder on
# first use there, which parks a scheduled agent in `blocked` before it reads its prompt.
# Run `claude` by hand in each directory a job targets and accept the prompt.
{ username, ... }:

{
  # The server is a user unit. Without linger it would only start at first login and die
  # with the last session, which is exactly when the scheduled jobs need it.
  users.users.${username}.linger = true;

  # Moshi uses mosh for the durable phone connection. openFirewall defaults to true and
  # would publish the UDP range on every interface; the phone arrives over the tailnet,
  # so scope it there instead (modules/tailscale.nix explains why tailscale0 is
  # deliberately not a trusted interface).
  programs.mosh = {
    enable = true;
    openFirewall = false;
  };
  networking.firewall.interfaces."tailscale0".allowedUDPPortRanges = [
    { from = 60000; to = 61000; }
  ];
}
