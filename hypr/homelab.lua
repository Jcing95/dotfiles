hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "auto", scale = 1 })

hl.env("HYPRCURSOR_THEME", "Nordzy-hyprcursors-white")
hl.env("HYPRCURSOR_SIZE",  "24")
hl.env("XCURSOR_THEME",    "Nordzy-cursors-white")
hl.env("XCURSOR_SIZE",     "24")

-- Hardware video decode: route VAAPI/VDPAU through NVDEC (GTX 980).
-- Must be set on the Hyprland session (not just NixOS environment.variables,
-- which only reaches login shells) so apps launched from a keybind/rofi inherit
-- them. Without this, browser video falls back to CPU software decode = stutter.
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("VDPAU_DRIVER",      "nvidia")
hl.env("NVD_BACKEND",       "direct")

hl.on("hyprland.start", function()
    hl.exec_cmd("waybar -c ~/.config/waybar/config-homelab.jsonc -s ~/.config/waybar/style-homelab.css")
end)
