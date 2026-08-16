-- Long-running daemons go through `uwsm app` so they land in
-- app-graphical.slice with their own cgroup, instead of inheriting the
-- compositor's. The wallpaper script stays a plain child: it is a one-shot that
-- waits for awww-daemon and exits, so a transient unit buys nothing.
--
-- hypridle is not here anymore — it is services.hypridle in nix/home/*.nix now
-- that graphical-session.target actually activates.
hl.on("hyprland.start", function()
    hl.exec_cmd("uwsm app -- awww-daemon")
    hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/random-wallpaper.sh")
    hl.exec_cmd("uwsm app -- nm-applet --indicator")
end)
