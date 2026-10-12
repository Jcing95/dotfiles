hl.monitor({
	output = "desc:Samsung Electric Company Odyssey G95NC HNTWB00204",
	mode = "highres@highrr",
	position = "auto",
	scale = 1.2,
	bitdepth = 10,
	cm = "hdr",
	-- from the panel's EDID HDR metadata
	max_luminance = 1015,
	max_avg_luminance = 604,
	min_luminance = 0,
	-- BT.2408 reference white; Hyprland's 80-nit default makes SDR dim
	sdr_max_luminance = 203,
	sdr_min_luminance = 0,
})
hl.monitor({ output = "", mode = "preferred", position = "auto-center-down", scale = 1 })

hl.env("HYPRCURSOR_THEME", "Nordzy-hyprcursors-white")
hl.env("HYPRCURSOR_SIZE", "36")
hl.env("XCURSOR_THEME", "Nordzy-cursors-white")
hl.env("XCURSOR_SIZE", "36")

hl.config({
	misc = { vrr = 1 },
	xwayland = { force_zero_scaling = true },
	-- fullscreen auto-switch re-syncs the monitor
	render = { cm_auto_hdr = 0 },
})

hl.on("hyprland.start", function()
	hl.exec_cmd("uwsm app -- waybar")
end)
