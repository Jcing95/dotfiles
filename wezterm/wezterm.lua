-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices
config.default_prog = { 'C:/Program Files/PowerShell/7-preview/pwsh.exe' }

config.default_cursor_style = 'BlinkingBar'
config.front_end = 'WebGpu'
config.webgpu_power_preference = 'HighPerformance'
config.window_frame = {
      active_titlebar_bg = 'hsl(120,66%,8%)',
    button_bg = '#FF0000',--'hsl(120,33%,5%)',
    font = require('wezterm').font 'FiraCode Nerd Font',
}
config.window_decorations = 'RESIZE'
config.color_scheme = 'Ayu Dark (Gogh)'
config.font = wezterm.font 'FiraCode Nerd Font'
config.window_background_gradient = {
    colors = {
    	'hsl(120,33%,5%)',
    	'hsl(120,87%,10%)',
    	'hsl(120,66%,5%)',
    },
    noise = 128,
    interpolation = 'Basis',
    blend = 'Oklab',
    orientation = {
	    Radial = {
	      cx = 1.2,
	      cy = -0.1,
	      radius = 1,
	    },
    }
}
config.window_background_opacity = 1
config.text_background_opacity = 1 
config.initial_rows = 48 
config.initial_cols = 160
config.macos_window_background_blur = 10
config.send_composed_key_when_left_alt_is_pressed = true



-- and finally, return the configuration to wezterm
return config

