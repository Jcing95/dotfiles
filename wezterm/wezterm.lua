-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices
if wezterm.target_triple:find('windows') then
  config.default_prog = { 'C:/Program Files/PowerShell/7-preview/pwsh.exe' }
end
config.debug_key_events = true
config.default_cursor_style = 'BlinkingBar'
config.front_end = 'WebGpu'
config.webgpu_power_preference = 'LowPower'
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
config.window_background_opacity = 0.75
config.text_background_opacity = 0.8 
config.initial_rows = 48 
config.initial_cols = 160
config.macos_window_background_blur = 10
config.send_composed_key_when_left_alt_is_pressed = true
config.leader = { key='b', mods='CTRL' }
config.disable_default_key_bindings = true
config.keys = {
  { key = "b", mods = "LEADER|CTRL",  action=wezterm.action{SendString="\x02"}},
  { key ="v",  mods="SHIFT|CTRL",    action=wezterm.action.PasteFrom 'Clipboard'},
  { key ="c",  mods="SHIFT|CTRL",    action=wezterm.action.CopyTo 'Clipboard'},
  { key = '*', mods='SHIFT|CTRL', action ='IncreaseFontSize' },
  { key = '_', mods='SHIFT|CTRL', action ='DecreaseFontSize' },
  { key = '=', mods='SHIFT|CTRL', action ='ResetFontSize' },
  { key = '%', mods='LEADER|SHIFT', action =wezterm.action{SplitVertical={domain='CurrentPaneDomain'}}},
  { key = '"', mods='LEADER|SHIFT', action =wezterm.action{SplitHorizontal={domain='CurrentPaneDomain'}}},
  { key = "h", mods = "LEADER", action=wezterm.action{ActivatePaneDirection="Left"}},
  { key = "j", mods = "LEADER", action=wezterm.action{ActivatePaneDirection="Down"}},
  { key = "k", mods = "LEADER", action=wezterm.action{ActivatePaneDirection="Up"}},
  { key = "l", mods = "LEADER", action=wezterm.action{ActivatePaneDirection="Right"}},
  { key = "LeftArrow", mods = "CTRL|SHIFT", action=wezterm.action{AdjustPaneSize={"Left", 2}}},
  { key = "DownArrow", mods = "CTRL|SHIFT", action=wezterm.action{AdjustPaneSize={"Down", 2}}},
  { key = "UpArrow", mods = "CTRL|SHIFT", action=wezterm.action{AdjustPaneSize={"Up", 2}}},
  { key = "RightArrow", mods = "CTRL|SHIFT", action=wezterm.action{AdjustPaneSize={"Right", 2}}},
}

-- and finally, return the configuration to wezterm
return config

