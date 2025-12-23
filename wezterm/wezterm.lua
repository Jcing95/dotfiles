local wezterm = require 'wezterm'

local config = wezterm.config_builder()

config.color_scheme = "Ayu Dark (Gogh)"
config.window_close_confirmation = "NeverPrompt"
config.default_cursor_style = "BlinkingBar"
config.front_end = "WebGpu"
config.webgpu_power_preference = "LowPower"
config.window_frame = {
	active_titlebar_bg = "hsl(120,66%,8%)",
	button_bg = "#FF0000", --'hsl(120,33%,5%)',
	font = require("wezterm").font("FiraCode Nerd Font"),
}
config.font = wezterm.font("FiraCode Nerd Font")
config.window_background_gradient = {
	colors = {
		"hsl(120,33%,5%)",
		"hsl(120,87%,10%)",
		"hsl(120,66%,5%)",
	},
	noise = 128,
	interpolation = "Basis",
	blend = "Oklab",
	orientation = {
		Radial = {
			cx = 1.2,
			cy = -0.1,
			radius = 1,
		},
	},
}
config.window_background_opacity = 0.75
config.text_background_opacity = 0.8

return config;

