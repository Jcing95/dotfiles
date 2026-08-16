-- uwsm runs Hyprland as wayland-wm@hyprland.desktop.service, which is
-- Type=notify with TimeoutStartSec=30. `uwsm finalize` sends that readiness
-- notification — without it systemd tears the whole session down after 30s.
--
-- It also exports WAYLAND_DISPLAY and DISPLAY into the systemd user manager,
-- plus whatever uwsm's hyprland plugin lists in UWSM_FINALIZE_VARNAMES
-- (HYPRLAND_INSTANCE_SIGNATURE, HYPRCURSOR_*, XCURSOR_*). Units that gate on
-- ConditionEnvironment=WAYLAND_DISPLAY — hypridle, the Hyprland portal — only
-- start once this has run.
--
-- Required first in hyprland.lua so this handler is registered, and therefore
-- runs, before any other hyprland.start autostart.
hl.on("hyprland.start", function()
    hl.exec_cmd("uwsm finalize")
end)
