local mainMod     = "SUPER"
local terminal    = "wezterm"
local fileManager = "thunar"
local menu        = "rofi -show drun"
local browser     = "brave"

-- Resize active window (percentage values not supported by hl.dsp.window.resize, so dispatch via hyprctl)
hl.bind(mainMod .. " + U", hl.dsp.exec_cmd("hyprctl dispatch resizeactive -10% 0"))
hl.bind(mainMod .. " + I", hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 -10%"))
hl.bind(mainMod .. " + O", hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 10%"))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("hyprctl dispatch resizeactive 10% 0"))

-- Move window
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))

-- Apps + window actions
hl.bind(mainMod .. " + RETURN",                 hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q",                      hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + CTRL + Delete",  hl.dsp.exec_cmd("systemctl poweroff"))
hl.bind(mainMod .. " + CTRL + Delete",          hl.dsp.exec_cmd("wlogout"))
hl.bind(mainMod .. " + E",                      hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + B",                      hl.dsp.exec_cmd(browser .. " --profile-directory='Default'"))
hl.bind(mainMod .. " + SHIFT + B",              hl.dsp.exec_cmd(browser .. " --incognito"))
hl.bind(mainMod .. " + CTRL + B",               hl.dsp.exec_cmd(browser .. " --profile-directory='Profile 1'"))
hl.bind(mainMod .. " + SHIFT + V",              hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SPACE",                  hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + V",                      hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + CTRL + L",               hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + S",                      hl.dsp.exec_cmd("hyprshot -m region --clipboard-only"))
hl.bind("Print",                                hl.dsp.exec_cmd("hyprshot -m output --clipboard-only"))
hl.bind("SHIFT + Print",                        hl.dsp.exec_cmd("hyprshot -m window --clipboard-only"))

-- Focus
hl.bind(mainMod .. " + H",   hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L",   hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K",   hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J",   hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + TAB", hl.dsp.window.cycle_next())

-- Workspaces 1-10 (switch + move active window)
for i = 1, 10 do
    local key = i % 10 -- 10 → key 0
    hl.bind(mainMod .. " + " .. key,           hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key,   hl.dsp.window.move({ workspace = i }))
end

-- Toggle laptop display
hl.bind(mainMod .. " + F7", hl.dsp.exec_cmd("hyprctl dispatch dpms toggle eDP-1"))

-- Scroll through workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize with mouse drag
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Multimedia / brightness
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
