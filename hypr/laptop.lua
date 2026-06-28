hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

hl.env("HYPRCURSOR_THEME", "Nordzy-hyprcursors-white")
hl.env("HYPRCURSOR_SIZE",  "24")
hl.env("XCURSOR_THEME",    "Nordzy-cursors-white")
hl.env("XCURSOR_SIZE",     "24")

hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
end)
