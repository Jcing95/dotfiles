hl.monitor({ output = "desc:Samsung Electric Company Odyssey G95NC HNTWB00204",
             mode = "highres@120", position = "auto", scale = 1, vrr = 1 })
hl.monitor({ output = "", mode = "preferred", position = "auto-center-down", scale = 1 })

hl.env("HYPRCURSOR_THEME", "Nordzy-cursors")
hl.env("HYPRCURSOR_SIZE",  "36")
hl.env("XCURSOR_THEME",    "Nordzy-cursors")
hl.env("XCURSOR_SIZE",     "36")

hl.config({
    misc = { vrr = 1 },
})

hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
end)
