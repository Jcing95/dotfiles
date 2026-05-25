local mainMod = "SUPER"
local terminal = "wezterm"
local fileManager = "thunar"
local menu = "rofi -show drun"
local browser = "brave"

-- Resize active window by % of the active monitor (Lua API takes integer pixels only)
local function resizePct(dxPct, dyPct)
	return function()
		local mon = hl.get_active_monitor()
		if not mon then
			return
		end
		hl.dispatch(hl.dsp.window.resize({
			x = math.floor(mon.width * dxPct / 100),
			y = math.floor(mon.height * dyPct / 100),
			relative = true,
		}))
	end
end

hl.bind(mainMod .. "+ SHIFT + Z", resizePct(-2.5, 0))
hl.bind(mainMod .. "+ SHIFT + U", resizePct(0, -5))
hl.bind(mainMod .. "+ SHIFT + I", resizePct(0, 5))
hl.bind(mainMod .. "+ SHIFT + O", resizePct(2.5, 0))

-- Move window
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))

-- Apps + window actions
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + CTRL + ESCAPE", hl.dsp.exec_cmd("systemctl poweroff"))
hl.bind(mainMod .. " + CTRL + Delete", hl.dsp.exec_cmd("wlogout"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser .. " --profile-directory='Default'"))
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd(browser .. " --incognito"))
hl.bind(mainMod .. " + CTRL + B", hl.dsp.exec_cmd(browser .. " --profile-directory='Profile 1'"))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + V", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + CTRL + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("hyprshot -m region --clipboard-only"))
hl.bind("Print", hl.dsp.exec_cmd("hyprshot -m output --clipboard-only"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("hyprshot -m window --clipboard-only"))

-- Focus
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + TAB", hl.dsp.window.cycle_next())

-- Workspaces 1-10 (switch + move active window)
for i = 1, 10 do
	local key = i % 10 -- 10 → key 0
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Toggle laptop display
hl.bind(mainMod .. " + F7", hl.dsp.exec_cmd("hyprctl dispatch dpms toggle eDP-1"))

-- Scroll the window under the pointer. ydotool 1.0.4 emits legacy REL_WHEEL (1 = ~1 notch).
-- Wayland routes wheel events by pointer position, NOT keyboard focus (input.follow_mouse = 0).
hl.bind(mainMod .. "+ U", hl.dsp.exec_cmd("ydotool mousemove -w -- 0 20"), { repeating = true })
hl.bind(mainMod .. "+ D", hl.dsp.exec_cmd("ydotool mousemove -w -- 0 -20"), { repeating = true })

-- Move/resize with mouse drag
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Multimedia / brightness
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
